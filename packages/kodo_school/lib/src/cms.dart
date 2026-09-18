/// The authoring CMS (M18).
///
/// *"A web tool in which a non-engineer authors worlds, concepts, tutorials, items, hints
/// and rubrics."* This file is the part of that tool which is not a screen: the draft
/// model, the editorial workflow, the audit trail, the publish gate and the bank file
/// format. A web front end renders it; it decides nothing.
///
/// The module prompt has exactly one `Do not`, and it is the reason for the shape of this
/// file: **do not allow an engineer-only path that bypasses the publish gate.** That is
/// not enforceable by a code review of a screen, so it is enforced by the types here.
/// [PublishedBank] has a private constructor and a private map; the only function in the
/// program that can put an item into one is [ContentCms.publish], and that function runs
/// the gate before it does. An engineer who wants to ship an ungated item has to edit this
/// library, which is a diff a reviewer can see.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:kodo_content/kodo_content.dart';
import 'package:kodo_grader/kodo_grader.dart';
import 'package:kodo_lang/kodo_lang.dart';

// ---------------------------------------------------------------------------------------
// People and the audit trail (FR-M18-03)
// ---------------------------------------------------------------------------------------

/// The three roles of `FR-M18-03`, plus the one the prompt implies by forbidding it.
enum CmsRole {
  /// Writes the content. An internal author or a partner teacher; the CMS does not know
  /// the difference and must not, or the partner teacher gets the second-class tool.
  author,

  /// Answers *is this taught correctly*.
  pedagogicalReviewer,

  /// Answers *does this read like a person wrote it, in both languages*.
  localisationReviewer,

  /// Can move content between projects and repair a stuck draft. Explicitly **cannot**
  /// publish: see [ContentCms.publish].
  administrator,
}

/// Somebody with a role. First name and a role is all the CMS needs; it is an internal
/// tool and it still does not collect more than it uses.
class CmsUser {
  const CmsUser({required this.id, required this.name, required this.roles});
  final String id;
  final String name;
  final Set<CmsRole> roles;

  bool can(CmsRole role) => roles.contains(role);
}

/// What happened, who did it, and when.
///
/// *"a full audit trail"*. Append-only: the CMS exposes the list as an unmodifiable view,
/// and nothing in this library removes an entry. A trail you can edit answers no question
/// worth asking.
class AuditEntry {
  const AuditEntry({
    required this.at,
    required this.draftId,
    required this.actorId,
    required this.action,
    required this.from,
    required this.to,
    this.note,
  });

  final DateTime at;
  final String draftId;
  final String actorId;

  /// A stable verb: `created`, `edited`, `submitted`, `approved`, `rejected`,
  /// `published`, `withdrawn`, `publish-refused`.
  final String action;

  final DraftState from;
  final DraftState to;

  /// A reviewer's reason, or the gate's first refusal. Free text, because a reason that
  /// has to fit a dropdown is not a reason.
  final String? note;

  Map<String, Object?> toJson() => {
        'at': at.toUtc().toIso8601String(),
        'draft': draftId,
        'actor': actorId,
        'action': action,
        'from': from.name,
        'to': to.name,
        if (note != null) 'note': note,
      };

  @override
  String toString() => '${at.toUtc().toIso8601String()} $actorId $action '
      '$draftId ${from.name}→${to.name}${note == null ? '' : ' ($note)'}';
}

/// Where a draft is in the workflow.
enum DraftState {
  /// The author owns it. Editable.
  draft,

  /// With the pedagogical reviewer. Not editable — an author who edits under review gets
  /// the reviewer approving a different item from the one they read.
  pedagogicalReview,

  /// With the localisation reviewer.
  localisationReview,

  /// Both reviews passed. The only state [ContentCms.publish] accepts.
  approved,

  /// In the bank.
  published,
}

/// Raised when somebody asks the CMS for a transition the workflow does not have.
///
/// A thrown error rather than a silent no-op, because the caller is a screen and a screen
/// that silently did nothing is how content goes missing.
class WorkflowError implements Exception {
  const WorkflowError(this.message);
  final String message;
  @override
  String toString() => 'WorkflowError: $message';
}

// ---------------------------------------------------------------------------------------
// What a non-engineer authors (FR-M18-01)
// ---------------------------------------------------------------------------------------

/// An item, plus everything the CMS needs that the runtime item does not carry.
///
/// [Item] is the shipping shape. A draft is the editing shape: it adds the audio keys the
/// publish gate asks for, the author's identity, and a revision counter so the audit trail
/// can say *which* version a reviewer approved.
class ItemDraft {
  const ItemDraft({
    required this.item,
    required this.authorId,
    required this.promptAudioKeys,
    this.revision = 1,
    this.state = DraftState.draft,
    this.pedagogicalApprovalBy,
    this.localisationApprovalBy,
  });

  final Item item;
  final String authorId;

  /// One recording key per required locale (`FR-M18-02`: *"FR and EN text and audio
  /// keys"*). A six-year-old in World 0 cannot read the prompt; the audio is not a
  /// nice-to-have, so it is a gate.
  final Map<String, String> promptAudioKeys;

  /// Bumped by every edit. A reviewer approves a revision, not an id.
  final int revision;

  final DraftState state;
  final String? pedagogicalApprovalBy;
  final String? localisationApprovalBy;

  String get id => item.id;

  ItemDraft copyWith({
    Item? item,
    Map<String, String>? promptAudioKeys,
    int? revision,
    DraftState? state,
    String? pedagogicalApprovalBy,
    String? localisationApprovalBy,
    bool clearApprovals = false,
  }) =>
      ItemDraft(
        item: item ?? this.item,
        authorId: authorId,
        promptAudioKeys: promptAudioKeys ?? this.promptAudioKeys,
        revision: revision ?? this.revision,
        state: state ?? this.state,
        pedagogicalApprovalBy:
            clearApprovals ? null : pedagogicalApprovalBy ?? this.pedagogicalApprovalBy,
        localisationApprovalBy:
            clearApprovals ? null : localisationApprovalBy ?? this.localisationApprovalBy,
      );
}

// ---------------------------------------------------------------------------------------
// Preview as child (FR-M18-01)
// ---------------------------------------------------------------------------------------

/// The reference device, as the preview simulates it.
///
/// §3 of the cahier: Android 11, 2 GB RAM, 5.5 inch. The number that matters to an author
/// writing a prompt is how many characters fit on a line at the child font size, because
/// the failure mode of an adult writing for a child is a prompt that wraps to four lines
/// and is skipped.
class ReferenceDevice {
  const ReferenceDevice({
    this.widthDp = 360,
    this.heightDp = 640,
    this.childFontSizeDp = 20,
    this.promptLines = 3,
  });

  final int widthDp;
  final int heightDp;
  final double childFontSizeDp;

  /// How many lines the prompt panel gives before it scrolls. A child does not scroll to
  /// find the rest of the instruction; they guess.
  final int promptLines;

  /// A monospace-ish average advance width. Crude on purpose: the preview is a warning
  /// system for authors, not a layout engine.
  double get averageGlyphWidthDp => childFontSizeDp * 0.55;

  int get charactersPerLine => (widthDp - 32) ~/ averageGlyphWidthDp;
}

/// One thing the preview wants the author to look at.
class PreviewNote {
  const PreviewNote(this.severity, this.rule, this.detail);

  /// `blocking` means the publish gate will refuse it too; `warning` means a child will
  /// struggle and a human should decide.
  final String severity;
  final String rule;
  final String detail;

  @override
  String toString() => '[$severity] $rule: $detail';
}

/// What a child would see, on the device they would see it on.
///
/// This is the `preview-as-child` of `FR-M18-01`. It runs the item's own reference
/// solution through the real interpreter, so the picture an author previews is the picture
/// a child gets — there is no second renderer here, per the one-AST rule.
class ChildPreview {
  const ChildPreview({
    required this.locale,
    required this.promptLines,
    required this.hintLines,
    required this.paletteScope,
    required this.strokes,
    required this.notes,
  });

  final String locale;
  final List<String> promptLines;
  final List<String> hintLines;
  final List<String> paletteScope;

  /// How many strokes the reference solution draws. Zero on an item whose reference
  /// solution draws nothing is the commonest authoring mistake after a missing hint.
  final int strokes;

  final List<PreviewNote> notes;

  bool get hasBlockingNotes => notes.any((n) => n.severity == 'blocking');

  static ChildPreview of(
    ItemDraft draft, {
    String locale = 'fr',
    ReferenceDevice device = const ReferenceDevice(),
  }) {
    final notes = <PreviewNote>[];
    final item = draft.item;

    final prompt = (item.promptKeys[locale] ?? '').trim();
    if (prompt.isEmpty) {
      notes.add(PreviewNote('blocking', 'prompt-missing', 'no prompt in "$locale"'));
    }

    List<String> wrap(String text) {
      final words = text.split(RegExp(r'\s+'))..removeWhere((w) => w.isEmpty);
      final lines = <String>[];
      var current = StringBuffer();
      for (final word in words) {
        final candidate = current.isEmpty ? word : '$current $word';
        if (candidate.length > device.charactersPerLine && current.isNotEmpty) {
          lines.add(current.toString());
          current = StringBuffer(word);
        } else {
          current = StringBuffer(candidate);
        }
      }
      if (current.isNotEmpty) lines.add(current.toString());
      return lines;
    }

    final promptLines = wrap(prompt);
    if (promptLines.length > device.promptLines) {
      notes.add(PreviewNote(
          'warning',
          'prompt-overflows',
          'wraps to ${promptLines.length} lines on a ${device.widthDp} dp screen, '
              'panel shows ${device.promptLines}'));
    }
    final readability = readabilityOf(prompt);
    for (final problem in readability.problems) {
      notes.add(PreviewNote('warning', 'reading-level', problem));
    }

    final hintLines = <String>[];
    for (var i = 0; i < item.hints.length; i++) {
      final text = item.hints[i].textIn(locale).trim();
      hintLines.add(text);
      if (text.isEmpty) {
        notes.add(PreviewNote('blocking', 'hint-missing', 'hint ${i + 1} has no "$locale" text'));
        continue;
      }
      for (final problem in readabilityOf(text).problems) {
        notes.add(PreviewNote('warning', 'reading-level', 'hint ${i + 1}: $problem'));
      }
    }

    var strokes = 0;
    final source = item.referenceSolutionSource;
    if (source != null && source.trim().isNotEmpty) {
      final parsed = parse(source, KeywordTables.of(locale));
      if (parsed.errors.isNotEmpty) {
        notes.add(PreviewNote('blocking', 'reference-parses',
            'the reference solution does not parse in "$locale"'));
      } else {
        final canvas = HeadlessCanvas();
        Interpreter(parsed.program, canvas, seed: item.seed).run();
        strokes = canvas.segments.length;
        if (strokes == 0 && item.type.wantsProgram && item.requireFinalPose == false) {
          notes.add(PreviewNote('warning', 'draws-nothing',
              'the reference solution draws nothing a child can see'));
        }
      }
    }

    for (final required in requiredLocales) {
      if ((draft.promptAudioKeys[required] ?? '').trim().isEmpty) {
        notes.add(PreviewNote('blocking', 'audio-key',
            'no "$required" recording key for the prompt'));
      }
    }

    return ChildPreview(
      locale: locale,
      promptLines: promptLines,
      hintLines: hintLines,
      paletteScope: item.paletteScope,
      strokes: strokes,
      notes: notes,
    );
  }
}

// ---------------------------------------------------------------------------------------
// The publish gate (FR-M18-02)
// ---------------------------------------------------------------------------------------

/// The CMS gate: the shipping gate of M6, plus the two things only the CMS knows about.
///
/// The bulk of the rule lives in `kodo_grader`'s [checkItem] because it has to *run the
/// grader*, and because CI must be able to apply it to a content pack without starting a
/// CMS. What is added here is what only exists in the editing shape: the audio keys, and
/// the rule that a reviewer's approval must be of the revision being published.
List<PublishFailure> checkDraft(ItemDraft draft, {Grader grader = const Grader()}) {
  final failures = <PublishFailure>[...checkItem(draft.item, grader: grader)];
  for (final locale in requiredLocales) {
    if ((draft.promptAudioKeys[locale] ?? '').trim().isEmpty) {
      failures.add(PublishFailure(
          draft.id, 'audio-key', 'no "$locale" recording key for the prompt'));
    }
  }
  if (draft.pedagogicalApprovalBy == null) {
    failures.add(PublishFailure(
        draft.id, 'pedagogical-review', 'no pedagogical reviewer has approved it'));
  }
  if (draft.localisationApprovalBy == null) {
    failures.add(PublishFailure(
        draft.id, 'localisation-review', 'no localisation reviewer has approved it'));
  }
  return failures;
}

/// The bank of items that have actually passed the gate.
///
/// Private constructor, private storage. Nothing outside this library can build one or add
/// to one; [ContentCms.publish] is the only door, and it runs [checkDraft] first. This is
/// the module prompt's `Do not` expressed as a type rather than as a convention.
class PublishedBank {
  PublishedBank._();

  final Map<String, Item> _items = {};
  final Map<String, Map<String, String>> _audio = {};

  List<Item> get items {
    final ids = _items.keys.toList()..sort();
    return [for (final id in ids) _items[id]!];
  }

  int get length => _items.length;

  Item? operator [](String id) => _items[id];

  Map<String, String> audioFor(String id) =>
      Map.unmodifiable(_audio[id] ?? const <String, String>{});

  void _put(Item item, Map<String, String> audio) {
    _items[item.id] = item;
    _audio[item.id] = Map.of(audio);
  }
}

// ---------------------------------------------------------------------------------------
// Bulk import and export (FR-M18-04)
// ---------------------------------------------------------------------------------------

/// A bank on disk: *"a documented structured format"*.
///
/// The acceptance test is *"an exported bank reimports with zero differences"*, so the
/// format is defined by the round trip rather than by the writer. Items are sorted by id
/// and every map is emitted in sorted key order, because a format whose bytes depend on
/// the order a `Map` happened to be built in cannot be diffed in review, and a bank that
/// cannot be diffed cannot be audited.
class ItemBankFile {
  const ItemBankFile({
    required this.schema,
    required this.bankId,
    required this.items,
    required this.audio,
  });

  /// Bumped when the shape changes. An import refuses a schema it does not know rather
  /// than guessing, because guessing corrupts an item bank quietly.
  static const currentSchema = 'kodo.itembank/1';

  final String schema;
  final String bankId;
  final List<Item> items;

  /// item id → locale → recording key.
  final Map<String, Map<String, String>> audio;

  static ItemBankFile ofBank(PublishedBank bank, {required String bankId}) =>
      ItemBankFile(
        schema: currentSchema,
        bankId: bankId,
        items: bank.items,
        audio: {
          for (final item in bank.items)
            if (bank.audioFor(item.id).isNotEmpty) item.id: bank.audioFor(item.id),
        },
      );

  /// Deterministic bytes. `_sorted` is applied to every nested map.
  String encode() {
    final sortedItems = [...items]..sort((a, b) => a.id.compareTo(b.id));
    final document = {
      'schema': schema,
      'bank': bankId,
      'items': [for (final item in sortedItems) item.toJson()],
      'audio': audio,
    };
    return const JsonEncoder.withIndent('  ').convert(_sorted(document));
  }

  /// The checksum a reviewer compares against a colleague's export.
  String get checksum => sha256.convert(utf8.encode(encode())).toString();

  static ItemBankFile decode(String text) {
    final document = jsonDecode(text) as Map<String, Object?>;
    final schema = document['schema'] as String?;
    if (schema != currentSchema) {
      throw FormatException('unknown item bank schema "$schema"');
    }
    return ItemBankFile(
      schema: schema!,
      bankId: document['bank']! as String,
      items: [
        for (final raw in (document['items']! as List<Object?>))
          Item.fromJson(raw! as Map<String, Object?>),
      ],
      audio: {
        for (final entry in ((document['audio'] as Map<String, Object?>?) ?? const {}).entries)
          entry.key: (entry.value! as Map<String, Object?>).cast<String, String>(),
      },
    );
  }

  /// Every field that differs, by path. Empty means the two banks are the same bank.
  List<String> differencesFrom(ItemBankFile other) {
    final differences = <String>[];
    final mine = {for (final i in items) i.id: i};
    final theirs = {for (final i in other.items) i.id: i};
    for (final id in {...mine.keys, ...theirs.keys}.toList()..sort()) {
      if (!theirs.containsKey(id)) {
        differences.add('items/$id: missing on the other side');
        continue;
      }
      if (!mine.containsKey(id)) {
        differences.add('items/$id: only on the other side');
        continue;
      }
      _diffJson('items/$id', _sorted(mine[id]!.toJson()), _sorted(theirs[id]!.toJson()),
          differences);
    }
    _diffJson('audio', _sorted(audio), _sorted(other.audio), differences);
    if (bankId != other.bankId) differences.add('bank: "$bankId" vs "${other.bankId}"');
    return differences;
  }

  static void _diffJson(String path, Object? mine, Object? theirs, List<String> into) {
    if (mine is Map && theirs is Map) {
      for (final key in {...mine.keys, ...theirs.keys}) {
        _diffJson('$path/$key', mine[key], theirs[key], into);
      }
      return;
    }
    if (mine is List && theirs is List) {
      if (mine.length != theirs.length) {
        into.add('$path: ${mine.length} entries vs ${theirs.length}');
        return;
      }
      for (var i = 0; i < mine.length; i++) {
        _diffJson('$path[$i]', mine[i], theirs[i], into);
      }
      return;
    }
    if (mine != theirs) into.add('$path: $mine vs $theirs');
  }
}

/// Recursively sorts map keys so encoding is deterministic.
Object? _sorted(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((k) => k as String).toList()..sort();
    return {for (final key in keys) key: _sorted(value[key])};
  }
  if (value is List) return [for (final entry in value) _sorted(entry)];
  return value;
}

// ---------------------------------------------------------------------------------------
// The CMS itself
// ---------------------------------------------------------------------------------------

/// The authoring CMS: drafts, the workflow, the trail and the bank.
class ContentCms {
  ContentCms({required this.clock, Grader grader = const Grader()}) : _grader = grader;

  /// Injected so the audit trail is reproducible in a test and honest in production.
  final DateTime Function() clock;

  final Grader _grader;

  final PublishedBank bank = PublishedBank._();

  final Map<String, ItemDraft> _drafts = {};
  final List<AuditEntry> _trail = [];

  List<AuditEntry> get auditTrail => List.unmodifiable(_trail);

  List<ItemDraft> get drafts {
    final ids = _drafts.keys.toList()..sort();
    return [for (final id in ids) _drafts[id]!];
  }

  ItemDraft? draft(String id) => _drafts[id];

  List<AuditEntry> trailFor(String draftId) =>
      _trail.where((e) => e.draftId == draftId).toList();

  void _record(String draftId, String actorId, String action, DraftState from,
          DraftState to, [String? note]) =>
      _trail.add(AuditEntry(
        at: clock(),
        draftId: draftId,
        actorId: actorId,
        action: action,
        from: from,
        to: to,
        note: note,
      ));

  // --- authoring -------------------------------------------------------------------------

  /// Creates a draft. Anybody with the author role, internal or partner.
  ItemDraft create(
    CmsUser actor, {
    required Item item,
    Map<String, String> promptAudioKeys = const {},
  }) {
    _require(actor, CmsRole.author, 'create a draft');
    if (_drafts.containsKey(item.id)) {
      throw WorkflowError('a draft with id "${item.id}" already exists');
    }
    if (bank[item.id] != null) {
      throw WorkflowError('"${item.id}" is already published; edit it to make revision 2');
    }
    final draft = ItemDraft(
      item: item,
      authorId: actor.id,
      promptAudioKeys: Map.of(promptAudioKeys),
    );
    _drafts[item.id] = draft;
    _record(item.id, actor.id, 'created', DraftState.draft, DraftState.draft);
    return draft;
  }

  /// Edits a draft. Only in [DraftState.draft]: a draft under review is what a reviewer is
  /// reading, and an item that changes underneath a reviewer is an approval of something
  /// nobody looked at.
  ItemDraft edit(
    CmsUser actor,
    String id, {
    Item? item,
    Map<String, String>? promptAudioKeys,
  }) {
    final current = _mustFind(id);
    _require(actor, CmsRole.author, 'edit a draft');
    if (current.state != DraftState.draft) {
      throw WorkflowError(
          '"$id" is in ${current.state.name} and cannot be edited; send it back first');
    }
    final next = current.copyWith(
      item: item,
      promptAudioKeys: promptAudioKeys,
      revision: current.revision + 1,
      clearApprovals: true,
    );
    _drafts[id] = next;
    _record(id, actor.id, 'edited', DraftState.draft, DraftState.draft,
        'revision ${next.revision}');
    return next;
  }

  // --- the workflow (FR-M18-03) ----------------------------------------------------------

  /// Author → pedagogical reviewer.
  ItemDraft submit(CmsUser actor, String id) {
    final current = _mustFind(id);
    _require(actor, CmsRole.author, 'submit a draft');
    if (current.state != DraftState.draft) {
      throw WorkflowError('"$id" is already in ${current.state.name}');
    }
    final next = current.copyWith(state: DraftState.pedagogicalReview);
    _drafts[id] = next;
    _record(id, actor.id, 'submitted', DraftState.draft, DraftState.pedagogicalReview,
        'revision ${current.revision}');
    return next;
  }

  /// Approves the stage a draft is in and moves it on.
  ///
  /// A reviewer may not approve their own draft even when they hold both roles. KODO is
  /// small enough that one person often does hold both, which is exactly why the rule is
  /// in the code and not in a handbook.
  ItemDraft approve(CmsUser actor, String id, {String? note}) {
    final current = _mustFind(id);
    if (actor.id == current.authorId) {
      throw WorkflowError('$id: an author cannot review their own draft');
    }
    switch (current.state) {
      case DraftState.pedagogicalReview:
        _require(actor, CmsRole.pedagogicalReviewer, 'approve pedagogy');
        final next = current.copyWith(
          state: DraftState.localisationReview,
          pedagogicalApprovalBy: actor.id,
        );
        _drafts[id] = next;
        _record(id, actor.id, 'approved', DraftState.pedagogicalReview,
            DraftState.localisationReview, note ?? 'revision ${current.revision}');
        return next;
      case DraftState.localisationReview:
        _require(actor, CmsRole.localisationReviewer, 'approve localisation');
        final next = current.copyWith(
          state: DraftState.approved,
          localisationApprovalBy: actor.id,
        );
        _drafts[id] = next;
        _record(id, actor.id, 'approved', DraftState.localisationReview,
            DraftState.approved, note ?? 'revision ${current.revision}');
        return next;
      case DraftState.draft:
      case DraftState.approved:
      case DraftState.published:
        throw WorkflowError('"$id" is in ${current.state.name}; there is nothing to approve');
    }
  }

  /// Sends a draft back to its author with a reason. The reason is required — a rejection
  /// without one is a partner teacher staring at a screen with no next action.
  ItemDraft reject(CmsUser actor, String id, String reason) {
    final current = _mustFind(id);
    if (reason.trim().isEmpty) {
      throw WorkflowError('a rejection needs a reason');
    }
    // Also from [DraftState.approved]: a reviewer who spots a problem after signing off,
    // before anybody published, must be able to say so. A workflow whose only direction is
    // forward gets that reviewer publishing an item they know is wrong.
    if (current.state != DraftState.pedagogicalReview &&
        current.state != DraftState.localisationReview &&
        current.state != DraftState.approved) {
      throw WorkflowError('"$id" is in ${current.state.name}; there is nothing to reject');
    }
    final next = current.copyWith(state: DraftState.draft, clearApprovals: true);
    _drafts[id] = next;
    _record(id, actor.id, 'rejected', current.state, DraftState.draft, reason);
    return next;
  }

  // --- publication -----------------------------------------------------------------------

  /// The only door into [bank].
  ///
  /// Refusals are returned, not thrown, and every one names a rule: the acceptance test is
  /// *"ten deliberately incomplete items, all rejected with a specific reason"*, and an
  /// author fixing content wants the whole list rather than a game of whack-a-mole. A
  /// refusal is written to the trail too — an item somebody tried and failed to publish is
  /// exactly the history a reviewer later wants.
  List<PublishFailure> publish(CmsUser actor, String id) {
    final current = _mustFind(id);
    // Not administrator, and not "engineer". There is no role that skips the gate below,
    // but there is also no role that skips the review either.
    _require(actor, CmsRole.author, 'publish');
    if (current.state != DraftState.approved) {
      final refusal = PublishFailure(id, 'workflow',
          'is in ${current.state.name}, needs both reviews before publication');
      _record(id, actor.id, 'publish-refused', current.state, current.state, refusal.detail);
      return [refusal];
    }
    final failures = checkDraft(current, grader: _grader);
    if (failures.isNotEmpty) {
      _record(id, actor.id, 'publish-refused', current.state, current.state,
          '${failures.length} rule(s): ${failures.first}');
      return failures;
    }
    bank._put(current.item, current.promptAudioKeys);
    _drafts[id] = current.copyWith(state: DraftState.published);
    _record(id, actor.id, 'published', DraftState.approved, DraftState.published,
        'revision ${current.revision}');
    return const [];
  }

  // --- bulk import and export (FR-M18-04) -------------------------------------------------

  /// Exports the published bank.
  ItemBankFile export({required String bankId}) =>
      ItemBankFile.ofBank(bank, bankId: bankId);

  /// Imports a bank file.
  ///
  /// Items arriving in a file are **not** exempt from the gate — that would be the
  /// engineer-only path the module prompt forbids, wearing a different hat. Each item is
  /// checked; the ones that pass land in the bank, the ones that do not are returned and
  /// recorded, and nothing half-imports silently.
  ImportReport import(CmsUser actor, ItemBankFile file) {
    _require(actor, CmsRole.author, 'import a bank');
    final accepted = <String>[];
    final refused = <PublishFailure>[];
    for (final item in file.items) {
      final audio = file.audio[item.id] ?? const <String, String>{};
      final asDraft = ItemDraft(
        item: item,
        authorId: actor.id,
        promptAudioKeys: audio,
        state: DraftState.approved,
        // An imported bank carries its own provenance: it was reviewed where it was
        // authored. The file is the record of that, and the trail says who imported it.
        pedagogicalApprovalBy: 'import:${file.bankId}',
        localisationApprovalBy: 'import:${file.bankId}',
      );
      final failures = checkDraft(asDraft, grader: _grader);
      if (failures.isNotEmpty) {
        refused.addAll(failures);
        _record(item.id, actor.id, 'publish-refused', DraftState.approved,
            DraftState.approved, 'import refused: ${failures.first}');
        continue;
      }
      bank._put(item, audio);
      _drafts[item.id] = asDraft.copyWith(state: DraftState.published);
      accepted.add(item.id);
      _record(item.id, actor.id, 'published', DraftState.approved, DraftState.published,
          'imported from "${file.bankId}"');
    }
    return ImportReport(accepted: accepted, refused: refused);
  }

  // --- internals -------------------------------------------------------------------------

  ItemDraft _mustFind(String id) {
    final draft = _drafts[id];
    if (draft == null) throw WorkflowError('no draft "$id"');
    return draft;
  }

  void _require(CmsUser actor, CmsRole role, String what) {
    if (!actor.can(role)) {
      throw WorkflowError('${actor.name} does not hold ${role.name} and cannot $what');
    }
  }
}

/// What an import did.
class ImportReport {
  const ImportReport({required this.accepted, required this.refused});
  final List<String> accepted;
  final List<PublishFailure> refused;
  bool get clean => refused.isEmpty;
}
