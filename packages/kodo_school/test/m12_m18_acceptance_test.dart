/// M12 and M18 acceptance tests.
///
/// **M12:** a no-internet drill seeds and collects 35 devices in under 20 minutes · a
/// teacher who has never seen KODO creates a class, assigns a world and reads the grid
/// unassisted · printed sheets are legible in monochrome on a low-toner printer.
///
/// **M18:** a partner teacher authors and publishes five items that pass review · ten
/// deliberately incomplete items are all rejected with a specific reason · an exported
/// bank reimports with zero differences.
library;

import 'dart:convert';
import 'dart:io';

import 'package:kodo_content/kodo_content.dart';
import 'package:kodo_grader/kodo_grader.dart';
import 'package:kodo_progress/kodo_progress.dart';
import 'package:kodo_school/kodo_school.dart';
import 'package:test/test.dart';

ContentPack loadWorld1() {
  final file = File('../../content/world1.json');
  if (!file.existsSync()) {
    fail('content/world1.json is missing — run '
        '`dart run tool/author_world1.dart` in packages/kodo_content');
  }
  return ContentPack.fromJson(
      jsonDecode(file.readAsStringSync()) as Map<String, Object?>);
}

MasteryState stateOf(String conceptId, ConceptState state) => MasteryState(
      conceptId: conceptId,
      state: state,
      evidence: const MasteryEvidence(
        itemsPassed: 0,
        typesSpanned: 0,
        firstAttemptRate: 0,
        passedDissimilar: false,
        criteriaOneToThreeMetAt: null,
        retentionPassedAt: null,
      ),
      lastTouchedAt: DateTime.utc(2026, 3, 2),
    );

void main() {
  final world1 = loadWorld1();
  final conceptIds = world1.concepts.keys.toList()..sort();

  // =====================================================================================
  // M12 — classroom mode
  // =====================================================================================

  group('FR-M12-01 · a class, a code, and pupils with a first name only', () {
    test('a teacher creates a class and gets a code they can read aloud', () {
      final room = Classroom(
        id: 'c1',
        name: 'CM1 B',
        code: ClassCode.fromSeed(20260302),
        teacherName: 'Mme Ndiaye',
      );
      expect(room.code.isValid, isTrue);
      expect(room.code.value, hasLength(ClassCode.length));
      // No confusable pair may have both members in the alphabet, or the code gets read
      // back wrongly when it is shouted across a room at 35 children.
      const confusable = [
        ('0', 'O'), ('1', 'I'), ('1', 'L'), ('I', 'L'),
        ('5', 'S'), ('8', 'B'), ('2', 'Z'), ('6', 'G'),
      ];
      for (final (a, b) in confusable) {
        expect(ClassCode.alphabet.contains(a) && ClassCode.alphabet.contains(b), isFalse,
            reason: '"$a" and "$b" are both in the alphabet and look alike');
      }
    });

    test('joining needs the code and a first name — nothing else', () {
      final room = Classroom(
          id: 'c1', name: 'CM1 B', code: const ClassCode('ABCDEF'), teacherName: 'T');
      final pupil =
          room.join(firstName: 'Awa', using: const ClassCode('ABCDEF'), at: DateTime.utc(2026, 3, 2));
      expect(pupil.firstName, 'Awa');
      expect(room.pupils, hasLength(1));
      expect(
          () => room.join(
              firstName: 'Moussa',
              using: const ClassCode('ZZZZZZ'),
              at: DateTime.utc(2026, 3, 2)),
          throwsArgumentError);
    });

    test('two children called Awa are told apart without a surname', () {
      final room = Classroom(
          id: 'c1', name: 'CM1 B', code: const ClassCode('ABCDEF'), teacherName: 'T');
      final at = DateTime.utc(2026, 3, 2);
      final one = room.join(firstName: 'Awa', using: const ClassCode('ABCDEF'), at: at);
      final two = room.join(firstName: 'Awa', using: const ClassCode('ABCDEF'), at: at);
      final alone = room.join(firstName: 'Moussa', using: const ClassCode('ABCDEF'), at: at);

      expect(one.displayNameAmong(room.pupils), startsWith('Awa '));
      expect(two.displayNameAmong(room.pupils), startsWith('Awa '));
      expect(one.displayNameAmong(room.pupils),
          isNot(two.displayNameAmong(room.pupils)));
      // A child with no clash keeps a bare first name — no initial appears "just in case".
      expect(alone.displayNameAmong(room.pupils), 'Moussa');
      // The disambiguator is the order they joined — never a family name, which the
      // classroom does not hold and must not display.
      expect(one.displayNameAmong(room.pupils), 'Awa (1)');
      expect(two.displayNameAmong(room.pupils), 'Awa (2)');
    });
  });

  group('FR-M12-02 · assignment and the live mastery grid', () {
    test('a world is assigned with a due date and the grid is pupil × concept', () {
      final room = Classroom(
          id: 'c1', name: 'CM1 B', code: const ClassCode('ABCDEF'), teacherName: 'T');
      final at = DateTime.utc(2026, 3, 2);
      final awa = room.join(firstName: 'Awa', using: const ClassCode('ABCDEF'), at: at);
      final moussa =
          room.join(firstName: 'Moussa', using: const ClassCode('ABCDEF'), at: at);

      room.assignments.add(Assignment(
        id: 'a1',
        scope: AssignmentScope.world,
        targetIds: const ['2'],
        dueOn: DateTime.utc(2026, 3, 16),
      ));
      expect(room.assignments.single.scope, AssignmentScope.world);
      expect(room.assignments.single.dueOn.isAfter(at), isTrue);

      final grid = room.grid({
        awa.id: {
          'C1.1': stateOf('C1.1', ConceptState.maitrise),
          'C1.2': stateOf('C1.2', ConceptState.enCours),
        },
        moussa.id: {'C1.1': stateOf('C1.1', ConceptState.aRevoir)},
      }, conceptIds);

      expect(grid, hasLength(room.pupils.length * conceptIds.length));
      final awaC11 =
          grid.firstWhere((c) => c.pupilId == awa.id && c.conceptId == 'C1.1');
      expect(awaC11.state, ConceptState.maitrise);
      expect(awaC11.stars, 3);
      // A concept nobody has touched is "not seen", not a blank the teacher has to read
      // as either "no data" or "failed".
      final untouched =
          grid.firstWhere((c) => c.pupilId == moussa.id && c.conceptId == 'C1.5');
      expect(untouched.state, ConceptState.nonVu);
    });
  });

  group('FR-M12-03 · acceptance 1 — the no-internet drill', () {
    // A teacher device holding three worlds at the §FR-M14-02 ceiling. World 1 measures
    // 360 kB of JSON plus ~9 MB of recordings, so a world at budget is the honest figure
    // to rehearse against rather than the JSON alone.
    final manifest = jsonEncode({
      'worlds': [0, 1, 2],
      'packs': ['world0.json', 'world1.json', 'world2.json'],
    });
    final bundle = SeedBundle(
      worlds: const [0, 1, 2],
      payload: manifest,
      checksum: SeedBundle.of(const [0, 1, 2], manifest).checksum,
      bytes: 3 * ContentPack.worldBudgetBytes,
    );
    final devices = [for (var i = 1; i <= 35; i++) 'tab-$i'];
    const seeder = ClassroomSeeder();

    test('35 devices are seeded and collected in under 20 minutes, no internet', () {
      final total = seeder.wholeDrill(
        bundle: bundle,
        deviceIds: devices,
        transport: SeedTransport.hotspot,
        // One hour a week for a term: a pupil device carries a few hundred attempts.
        progressBytesPerDevice: 64 * 1024,
      );
      expect(total, lessThan(const Duration(minutes: 20)),
          reason: 'the drill took ${total.inMinutes} min ${total.inSeconds % 60} s');
      expect(total, greaterThan(Duration.zero));
    });

    test('a hotspot is modelled as contended, or the drill passes only on paper', () {
      final few = seeder.seed(
          bundle: bundle, deviceIds: devices.take(5).toList(), transport: SeedTransport.hotspot);
      final many =
          seeder.seed(bundle: bundle, deviceIds: devices, transport: SeedTransport.hotspot);
      expect(many.first.seconds, greaterThan(few.first.seconds),
          reason: 'one hotspot for 35 devices is slower per device than for 5');
    });

    test('a card is faster per device but serial, and the drill still fits', () {
      final outcomes =
          seeder.seed(bundle: bundle, deviceIds: devices, transport: SeedTransport.sdCard);
      expect(outcomes.first.seconds,
          lessThan(seeder
              .seed(bundle: bundle, deviceIds: devices, transport: SeedTransport.hotspot)
              .first
              .seconds));
      expect(seeder.drillDuration(outcomes, SeedTransport.sdCard),
          lessThan(const Duration(minutes: 20)));
    });

    test('the checksum is recomputed on the receiving device, so tampering is caught', () {
      expect(bundle.verifies(), isTrue);
      final tampered = SeedBundle(
        worlds: bundle.worlds,
        payload: '${bundle.payload}!',
        checksum: bundle.checksum,
        bytes: bundle.bytes,
      );
      expect(tampered.verifies(), isFalse);
      final outcomes = seeder.seed(
          bundle: tampered, deviceIds: devices, transport: SeedTransport.usb);
      expect(outcomes.every((o) => !o.accepted), isTrue);
      // A refusal a teacher can act on, not a stack trace.
      expect(outcomes.first.refusedBecause, 'seed.checksum_mismatch');
    });
  });

  group('FR-M12-04 · printed sheets survive a low-toner printer', () {
    final room = Classroom(
        id: 'c1', name: 'CM1 B', code: const ClassCode('ABCDEF'), teacherName: 'T');
    final at = DateTime.utc(2026, 3, 2);
    final pupils = [
      for (final name in ['Awa', 'Moussa', 'Fatou', 'Ibrahima'])
        room.join(firstName: name, using: const ClassCode('ABCDEF'), at: at)
    ];

    final sheet = ProgressSheet(
      className: 'CM1 B — Monde 1',
      conceptIds: conceptIds,
      rows: room.grid({
        pupils[0].id: {'C1.1': stateOf('C1.1', ConceptState.maitrise)},
        pupils[1].id: {'C1.1': stateOf('C1.1', ConceptState.aRevoir)},
        pupils[2].id: {'C1.2': stateOf('C1.2', ConceptState.enCours)},
      }, conceptIds),
    );

    test('every state is a distinct character, never a colour or a grey blob', () {
      final glyphs = ProgressSheet.glyphs.values.toList();
      expect(glyphs.toSet(), hasLength(ConceptState.values.length));
      for (final glyph in glyphs) {
        expect(glyph, hasLength(1));
        // A filled circle or a block becomes the same smudge at low toner.
        expect('●■▪◆'.contains(glyph), isFalse);
      }
    });

    test('the legend explains every glyph, in both languages', () {
      for (final locale in ['fr', 'en']) {
        for (final glyph in ProgressSheet.glyphs.values) {
          expect(ProgressSheet.legend[locale], contains(glyph),
              reason: '"$glyph" is unexplained in $locale');
        }
      }
    });

    test('the sheet fits A4 and names no child but by their first name', () {
      final rendered = sheet.render(pupils);
      for (final line in rendered.split('\n')) {
        // 80 columns is what a 10 pt monospace gives on A4 portrait.
        expect(line.length, lessThanOrEqualTo(80), reason: 'line overflows A4: "$line"');
      }
      for (final pupil in pupils) {
        expect(rendered, contains(pupil.firstName));
      }
      expect(rendered, contains('maîtrisé'));
      // The states actually reached appear as their glyphs.
      expect(rendered, contains('#'));
      expect(rendered, contains('~'));
    });
  });

  group('FR-M12-05 · projection mode', () {
    test('the back row can read it, or it is not projection mode', () {
      expect(const ProjectionSettings().isLegibleFromTheBackRow, isTrue);
      expect(const ProjectionSettings(fontSize: 18).isLegibleFromTheBackRow, isFalse);
      // High contrast is not optional: a projector in a lit classroom loses most of it.
      expect(const ProjectionSettings(fontSize: 48, highContrast: false)
          .isLegibleFromTheBackRow, isFalse);
    });
  });

  group('FR-M12 · acceptance 2 — the unassisted first run', () {
    // The claim is *"a teacher who has never seen KODO creates a class, assigns World 2
    // and reads the grid in under 10 minutes, unassisted"*. Ten minutes is a stopwatch
    // reading against a real teacher, and this file cannot produce one; what it can do is
    // hold the shape of the path so a regression does not quietly make the stopwatch
    // reading worse. The observation itself is scheduled evidence at G3 — see
    // docs/modules/M12_M18_DONE.md.
    test('the path is three actions and asks for nothing the teacher must go and find', () {
      final at = DateTime.utc(2026, 3, 2, 9);
      // 1 — create.
      final room = Classroom(
        id: 'c1',
        name: 'CM1 B',
        code: ClassCode.fromSeed(7),
        teacherName: 'Mme Ndiaye',
      );
      // 2 — assign.
      room.assignments.add(Assignment(
        id: 'a1',
        scope: AssignmentScope.world,
        targetIds: const ['2'],
        dueOn: at.add(const Duration(days: 14)),
      ));
      // 3 — read the grid, which exists before any pupil has joined.
      final empty = room.grid(const {}, conceptIds);
      expect(empty, isEmpty);

      final awa = room.join(firstName: 'Awa', using: room.code, at: at);
      expect(room.grid({awa.id: const {}}, conceptIds), hasLength(conceptIds.length));

      // Nothing on the path needed an email address, a password, a payment, or a network
      // call — the four things that turn a ten-minute first run into a lost hour.
      expect(room.teacherName, isNotEmpty);
      expect(room.code.isValid, isTrue);
    });
  });

  // =====================================================================================
  // M18 — the authoring CMS
  // =====================================================================================

  Item worldItem(int index) => world1.items[index];

  Map<String, String> audioFor(Item item) =>
      world1.itemAudioKeys[item.id] ?? const {};

  var tick = DateTime.utc(2026, 4, 1, 9);
  DateTime clock() => tick = tick.add(const Duration(minutes: 1));

  ContentCms freshCms() {
    tick = DateTime.utc(2026, 4, 1, 9);
    return ContentCms(clock: clock);
  }

  const teacher = CmsUser(
      id: 'u-partner', name: 'M. Diallo', roles: {CmsRole.author});
  const pedagogue = CmsUser(
      id: 'u-ped', name: 'Seat 3', roles: {CmsRole.pedagogicalReviewer});
  const translator = CmsUser(
      id: 'u-loc', name: 'Seat 11', roles: {CmsRole.localisationReviewer});
  const admin = CmsUser(
      id: 'u-admin', name: 'Ops', roles: {CmsRole.administrator});

  group('FR-M18-01 · preview as child, on the reference device', () {
    test('the preview runs the item\'s own reference solution, not a second renderer', () {
      final item = world1.items.firstWhere((i) => i.type == ItemType.t1BuildToTarget);
      final preview = ChildPreview.of(ItemDraft(
        item: item,
        authorId: teacher.id,
        promptAudioKeys: audioFor(item),
      ));
      expect(preview.strokes, greaterThan(0),
          reason: '${item.id}: the reference solution draws nothing');
      expect(preview.hintLines, hasLength(item.hints.length));
      expect(preview.hasBlockingNotes, isFalse, reason: preview.notes.join('\n'));
    });

    test('a prompt that overflows the panel is flagged before a child meets it', () {
      final item = worldItem(0);
      final wordy = Item.fromJson({
        ...item.toJson(),
        'id': 'PREVIEW-01',
        'prompt': {
          'fr': 'Fais avancer Tika de cinquante pas vers le haut de l\'écran '
              'parce que la tortue doit absolument atteindre le bord bleu.',
          'en': 'Make the turtle go forward fifty steps.',
        },
      });
      final preview = ChildPreview.of(ItemDraft(
        item: wordy,
        authorId: teacher.id,
        promptAudioKeys: const {'fr': 'a.opus', 'en': 'b.opus'},
      ));
      expect(preview.notes.map((n) => n.rule), contains('reading-level'));
      expect(preview.promptLines.length, greaterThan(1));
      for (final line in preview.promptLines) {
        expect(line.length,
            lessThanOrEqualTo(const ReferenceDevice().charactersPerLine));
      }
    });

    test('a missing recording key is blocking in the preview, not a surprise at publish', () {
      final preview = ChildPreview.of(ItemDraft(
        item: worldItem(0),
        authorId: teacher.id,
        promptAudioKeys: const {'fr': 'a.opus'},
      ));
      expect(preview.hasBlockingNotes, isTrue);
      expect(preview.notes.where((n) => n.rule == 'audio-key').single.detail,
          contains('"en"'));
    });
  });

  group('FR-M18-03 · acceptance 1 — a partner teacher publishes five items', () {
    test('five items go author → pedagogy → localisation → publish, with no engineer', () {
      final cms = freshCms();
      final chosen = world1.items.take(5).toList();

      for (final item in chosen) {
        cms.create(teacher, item: item, promptAudioKeys: audioFor(item));
        // The preview is what the teacher looks at before submitting.
        expect(ChildPreview.of(cms.draft(item.id)!).hasBlockingNotes, isFalse,
            reason: ChildPreview.of(cms.draft(item.id)!).notes.join('\n'));
        cms.submit(teacher, item.id);
        cms.approve(pedagogue, item.id);
        cms.approve(translator, item.id);
        expect(cms.publish(teacher, item.id), isEmpty,
            reason: '${item.id} was refused');
      }

      expect(cms.bank.length, 5);
      for (final item in chosen) {
        expect(cms.draft(item.id)!.state, DraftState.published);
        expect(cms.bank[item.id], isNotNull);
      }
      // No engineer appears anywhere in the trail.
      expect(cms.auditTrail.map((e) => e.actorId).toSet(),
          {teacher.id, pedagogue.id, translator.id});
    });

    test('the audit trail records who did what, in order, and cannot be edited', () {
      final cms = freshCms();
      final item = worldItem(0);
      cms.create(teacher, item: item, promptAudioKeys: audioFor(item));
      cms.submit(teacher, item.id);
      cms.reject(pedagogue, item.id, 'the second hint gives the answer away');
      cms.submit(teacher, item.id);
      cms.approve(pedagogue, item.id, note: 'hint fixed');
      cms.approve(translator, item.id);
      cms.publish(teacher, item.id);

      final trail = cms.trailFor(item.id);
      expect(trail.map((e) => e.action).toList(),
          ['created', 'submitted', 'rejected', 'submitted', 'approved', 'approved', 'published']);
      expect(trail.map((e) => e.actorId).toList(), [
        teacher.id, teacher.id, pedagogue.id, teacher.id, pedagogue.id,
        translator.id, teacher.id,
      ]);
      // The rejection carries its reason, not a status code.
      expect(trail[2].note, 'the second hint gives the answer away');
      // Monotonic, so a reader can trust the order.
      for (var i = 1; i < trail.length; i++) {
        expect(trail[i].at.isAfter(trail[i - 1].at), isTrue);
      }
      expect(() => cms.auditTrail.removeAt(0), throwsUnsupportedError);
    });

    test('a rejection needs a reason', () {
      final cms = freshCms();
      final item = worldItem(0);
      cms.create(teacher, item: item, promptAudioKeys: audioFor(item));
      cms.submit(teacher, item.id);
      expect(() => cms.reject(pedagogue, item.id, '   '), throwsA(isA<WorkflowError>()));
    });

    test('an author cannot review their own draft, even holding both roles', () {
      final cms = freshCms();
      const both = CmsUser(
          id: 'u-both',
          name: 'Seat 4',
          roles: {CmsRole.author, CmsRole.pedagogicalReviewer});
      final item = worldItem(1);
      cms.create(both, item: item, promptAudioKeys: audioFor(item));
      cms.submit(both, item.id);
      expect(() => cms.approve(both, item.id), throwsA(isA<WorkflowError>()));
    });

    test('an edit under review is refused; an edit in draft clears both approvals', () {
      final cms = freshCms();
      final item = worldItem(2);
      cms.create(teacher, item: item, promptAudioKeys: audioFor(item));
      cms.submit(teacher, item.id);
      expect(() => cms.edit(teacher, item.id, promptAudioKeys: const {}),
          throwsA(isA<WorkflowError>()));

      cms.approve(pedagogue, item.id);
      cms.approve(translator, item.id);
      expect(cms.draft(item.id)!.state, DraftState.approved);

      // A reviewer who signed off and then spotted a problem can still send it back.
      cms.reject(translator, item.id, 'the English prompt reads like a translation');
      expect(cms.draft(item.id)!.state, DraftState.draft);
      final edited = cms.edit(teacher, item.id, item: item);
      expect(edited.revision, 2);
      expect(edited.pedagogicalApprovalBy, isNull);
      expect(edited.localisationApprovalBy, isNull);
      // Which means it cannot be published on yesterday's approval.
      expect(cms.publish(teacher, item.id).map((f) => f.rule), contains('workflow'));
    });
  });

  group('FR-M18-02 · acceptance 2 — ten incomplete items, ten specific refusals', () {
    /// Ten ways an item is not finished. Each one is a real authoring mistake, not a
    /// mutation chosen to trip a branch.
    List<(String, ItemDraft)> brokenDrafts() {
      final good = worldItem(0);
      Map<String, Object?> based(Map<String, Object?> changes) =>
          {...good.toJson(), ...changes};

      ItemDraft draft(String id, Map<String, Object?> changes,
              {Map<String, String>? audio}) =>
          ItemDraft(
            item: Item.fromJson(based({'id': id, ...changes})),
            authorId: teacher.id,
            promptAudioKeys: audio ?? const {'fr': 'a.opus', 'en': 'b.opus'},
            state: DraftState.approved,
            pedagogicalApprovalBy: pedagogue.id,
            localisationApprovalBy: translator.id,
          );

      final hints = (good.toJson()['hints']! as List<Object?>);
      return [
        ('concept-link', draft('BAD-01', {'concept': '  '})),
        ('prompt-localised',
            draft('BAD-02', {'prompt': {'fr': 'Fais avancer Tika de 50 pas.'}})),
        ('two-hints', draft('BAD-03', {'hints': [hints.first]})),
        ('diagnostic-message', draft('BAD-04', {'diagnostics': const []})),
        (
          'generic-message',
          draft('BAD-05', {
            'diagnostics': [
              {
                'when': 'drewTooLittle',
                'text': {'fr': 'Faux.', 'en': 'Wrong.'}
              }
            ]
          })
        ),
        ('reference-solution', draft('BAD-06', {'reference': '   '})),
        ('three-wrong', draft('BAD-07', {'wrong': const ['avance 25']})),
        ('two-alternatives', draft('BAD-08', {'alternatives': const []})),
        // Asserted wrong, but it is the reference solution again.
        (
          'wrong-fails',
          draft('BAD-09', {
            'wrong': ['avance 50', 'recule 50', 'avance 90']
          })
        ),
        ('audio-key', draft('BAD-10', const {}, audio: const {'fr': 'a.opus'})),
      ];
    }

    test('all ten are refused, each naming the rule it tripped', () {
      final refusals = <String, List<PublishFailure>>{};
      for (final (expected, draft) in brokenDrafts()) {
        final failures = checkDraft(draft);
        refusals[draft.id] = failures;
        expect(failures, isNotEmpty, reason: '${draft.id} was let through');
        expect(failures.map((f) => f.rule), contains(expected),
            reason: '${draft.id} was refused for ${failures.map((f) => f.rule)} '
                'rather than $expected');
      }
      expect(refusals, hasLength(10));
      // A reason a human can act on: every refusal names a rule and says something
      // beyond "invalid".
      for (final failures in refusals.values) {
        for (final failure in failures) {
          expect(failure.rule, isNotEmpty);
          expect(failure.detail.split(' ').length, greaterThan(1));
        }
      }
    });

    test('the gate refuses them through the CMS too, and writes the refusal down', () {
      final cms = freshCms();
      for (final (expected, broken) in brokenDrafts()) {
        cms.create(teacher,
            item: broken.item, promptAudioKeys: broken.promptAudioKeys);
        cms.submit(teacher, broken.id);
        cms.approve(pedagogue, broken.id);
        cms.approve(translator, broken.id);
        final failures = cms.publish(teacher, broken.id);
        expect(failures.map((f) => f.rule), contains(expected));
        expect(cms.bank[broken.id], isNull);
        expect(cms.draft(broken.id)!.state, DraftState.approved);
        expect(cms.trailFor(broken.id).last.action, 'publish-refused');
        expect(cms.trailFor(broken.id).last.note, isNotNull);
      }
      expect(cms.bank.length, 0);
    });

    test('the shipped World 1 bank passes the same gate, audio included', () {
      final failures = <PublishFailure>[];
      for (final item in world1.items) {
        failures.addAll(checkDraft(ItemDraft(
          item: item,
          authorId: 'kodo',
          promptAudioKeys: audioFor(item),
          state: DraftState.approved,
          pedagogicalApprovalBy: pedagogue.id,
          localisationApprovalBy: translator.id,
        )));
      }
      expect(failures, isEmpty, reason: failures.take(5).join('\n'));
    });
  });

  group('M18 `Do not` · there is no engineer-only path around the gate', () {
    test('publishing is the only door into the bank, and it always gates', () {
      final cms = freshCms();
      final item = worldItem(0);
      cms.create(teacher, item: item, promptAudioKeys: audioFor(item));
      // Straight to publish, skipping both reviews.
      expect(cms.publish(teacher, item.id).map((f) => f.rule), contains('workflow'));
      expect(cms.bank.length, 0);
      // The bank has no public constructor and no public mutator: `bank.items` is a
      // copy, so writing to it changes nothing.
      cms.bank.items.clear();
      cms.submit(teacher, item.id);
      cms.approve(pedagogue, item.id);
      cms.approve(translator, item.id);
      expect(cms.publish(teacher, item.id), isEmpty);
      expect(cms.bank.length, 1);
      cms.bank.items.clear();
      expect(cms.bank.length, 1);
    });

    test('an administrator cannot publish, and no role skips the review', () {
      final cms = freshCms();
      final item = worldItem(0);
      cms.create(teacher, item: item, promptAudioKeys: audioFor(item));
      cms.submit(teacher, item.id);
      cms.approve(pedagogue, item.id);
      cms.approve(translator, item.id);
      expect(() => cms.publish(admin, item.id), throwsA(isA<WorkflowError>()));
      expect(cms.bank.length, 0);
    });

    test('an imported item is gated exactly like an authored one', () {
      final cms = freshCms();
      final good = worldItem(0);
      final bad = Item.fromJson({...good.toJson(), 'id': 'IMP-BAD', 'hints': const []});
      final file = ItemBankFile(
        schema: ItemBankFile.currentSchema,
        bankId: 'partner-school',
        items: [good, bad],
        audio: {
          good.id: audioFor(good),
          bad.id: const {'fr': 'a.opus', 'en': 'b.opus'},
        },
      );
      final report = cms.import(teacher, file);
      expect(report.clean, isFalse);
      expect(report.accepted, [good.id]);
      expect(report.refused.map((f) => f.rule), contains('two-hints'));
      expect(cms.bank['IMP-BAD'], isNull);
    });
  });

  group('FR-M18-04 · acceptance 3 — an exported bank reimports with zero differences', () {
    test('the round trip is byte-for-byte, over the whole World 1 bank', () {
      final cms = freshCms();
      final source = ItemBankFile(
        schema: ItemBankFile.currentSchema,
        bankId: 'world-1',
        items: world1.items,
        audio: {for (final i in world1.items) i.id: audioFor(i)},
      );
      final report = cms.import(teacher, source);
      expect(report.clean, isTrue, reason: report.refused.take(3).join('\n'));
      expect(report.accepted, hasLength(world1.items.length));

      final exported = cms.export(bankId: 'world-1');
      final reimported = ItemBankFile.decode(exported.encode());

      expect(exported.differencesFrom(reimported), isEmpty);
      expect(reimported.encode(), exported.encode());
      expect(reimported.checksum, exported.checksum);
      expect(reimported.items, hasLength(world1.items.length));

      // And a second CMS, on another machine, arrives at the same bank.
      final other = ContentCms(clock: () => DateTime.utc(2026, 5, 1));
      expect(other.import(teacher, reimported).clean, isTrue);
      expect(other.export(bankId: 'world-1').checksum, exported.checksum);
    });

    test('the encoding does not depend on the order a map was built in', () {
      final item = worldItem(0);
      final forwards = ItemBankFile(
        schema: ItemBankFile.currentSchema,
        bankId: 'b',
        items: [item],
        audio: {item.id: const {'fr': 'a.opus', 'en': 'b.opus'}},
      );
      final backwards = ItemBankFile(
        schema: ItemBankFile.currentSchema,
        bankId: 'b',
        items: [item],
        audio: {item.id: const {'en': 'b.opus', 'fr': 'a.opus'}},
      );
      expect(forwards.encode(), backwards.encode());
      expect(forwards.checksum, backwards.checksum);
    });

    test('a difference is reported by path, so a review can see what moved', () {
      final item = worldItem(0);
      final mine = ItemBankFile(
          schema: ItemBankFile.currentSchema, bankId: 'b', items: [item], audio: const {});
      final theirs = ItemBankFile(
        schema: ItemBankFile.currentSchema,
        bankId: 'b',
        items: [Item.fromJson({...item.toJson(), 'difficulty': 'D3'})],
        audio: const {},
      );
      final differences = mine.differencesFrom(theirs);
      expect(differences, hasLength(1));
      expect(differences.single, 'items/${item.id}/difficulty: D1 vs D3');
    });

    test('an unknown schema is refused rather than guessed at', () {
      expect(() => ItemBankFile.decode('{"schema":"kodo.itembank/99","bank":"b","items":[]}'),
          throwsFormatException);
    });
  });
}
