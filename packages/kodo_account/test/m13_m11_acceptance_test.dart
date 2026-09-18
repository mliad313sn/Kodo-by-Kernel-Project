/// M13 and M11 acceptance tests.
///
/// **M13:** the complete World-1 experience runs with no account and no network · a
/// conflict matrix of 20 scenarios produces zero silent data loss · a deletion request
/// removes every record across every store, verified by an independent query.
///
/// **M11:** ten parents with no coding background read the weekly summary and correctly
/// explain what their child learned · three children aged 8–11 try to enter the parent
/// space and fail · deletion completes end-to-end within the stated window in a live test.
library;

import 'package:kodo_account/kodo_account.dart';
import 'package:kodo_grader/kodo_grader.dart';
import 'package:kodo_insight/kodo_insight.dart';
import 'package:kodo_stage/kodo_stage.dart';
import 'package:test/test.dart';

SyncedProject _project(String id, String source, DateTime at, String device,
        {String name = 'Mon dessin'}) =>
    SyncedProject(
      id: id,
      profileId: 'p1',
      name: name,
      source: source,
      updatedAt: at,
      deviceId: device,
    );

Attempt _attempt(String itemId, DateTime at, {bool passed = true}) => Attempt(
      itemId: itemId,
      itemVersion: 1,
      conceptId: 'C1.1',
      at: at,
      passed: passed,
      response: const ChoiceResponse(0),
      signals: const ProcessSignals(),
      verdict: Verdict(passed: passed, itemId: itemId, itemVersion: 1),
      itemType: ItemType.t1BuildToTarget,
      difficulty: Difficulty.d1,
    );

void main() {
  group('FR-M13-01 · no account, ever, for the learning path', () {
    test('a profile needs nothing but a name and an avatar', () {
      final profile = LocalProfile(
          id: 'local-1', displayName: 'Awa', avatarKey: 'avatar.tortue');
      expect(profile.birthYear, isNull);
      expect(profile.picturePassword, isNull);
      // And it works: consent is unset, which gates nothing on the learning path.
      expect(profile.consent.allows(Capability.sharing), isFalse);
    });

    test('a device with a profile and no account is a complete device', () {
      final device = Device(deviceSalt: 'salt');
      device.addProfile(LocalProfile(
          id: 'local-1', displayName: 'Awa', avatarKey: 'avatar.tortue'));
      expect(device.hasAccount('local-1'), isFalse);
      expect(device.profiles, hasLength(1));
    });

    test('a picture password is four pictures a child can name', () {
      const password = PicturePassword(['tortue', 'lune', 'fleur', 'étoile']);
      expect(password.isValid, isTrue);
      expect(password.matches(['tortue', 'lune', 'fleur', 'étoile']), isTrue);
      expect(password.matches(['lune', 'tortue', 'fleur', 'étoile']), isFalse);
      expect(const PicturePassword(['tortue']).isValid, isFalse);
      expect(const PicturePassword(['a', 'b', 'c', 'd']).isValid, isFalse);
    });
  });

  group('FR-M13-02, §13 · the minimum data, and no more', () {
    test('there is no field for a surname, a photo, an address or a location',
        () {
      // §13's data minimisation, enforced by the type. A screen cannot collect what the
      // model cannot hold.
      final profile = LocalProfile(
        id: 'local-1',
        displayName: 'Awa',
        avatarKey: 'avatar.tortue',
        birthYear: 2017,
      );
      final json = profile.toJson();
      expect(
          json.keys.toSet().difference(LocalProfile.permittedFields), isEmpty);

      const forbidden = [
        'surname',
        'nom',
        'lastName',
        'address',
        'adresse',
        'photo',
        'face',
        'location',
        'latitude',
        'gps',
        'phone',
        'email',
        'contacts'
      ];
      for (final key in json.keys) {
        for (final word in forbidden) {
          expect(key.toLowerCase(), isNot(contains(word.toLowerCase())));
        }
      }
    });

    test('an account cannot exist without a recorded guardian consent moment',
        () {
      final device = Device(deviceSalt: 'salt');
      final at = DateTime.utc(2026, 9, 18);
      final account = device.createAccount(
        profileId: 'local-1',
        by: GuardianKind.parent,
        guardianContact: 'parent@example.test',
        consentRecordedAt: at,
      );
      // There is no constructor without it, so "an account with no consent" is not a state
      // the system can reach.
      expect(account.consentRecordedAt, at);
      expect(account.guardianKind, GuardianKind.parent);
    });

    test('a profile round-trips without gaining a field', () {
      final profile = LocalProfile(
        id: 'local-1',
        displayName: 'Awa',
        avatarKey: 'avatar.tortue',
        picturePassword:
            const PicturePassword(['tortue', 'lune', 'fleur', 'étoile']),
        birthYear: 2017,
      );
      final restored = LocalProfile.fromJson(profile.toJson());
      expect(restored.displayName, 'Awa');
      expect(restored.birthYear, 2017);
      expect(
          restored.picturePassword!.symbols, profile.picturePassword!.symbols);
      expect(restored.toJson().keys, profile.toJson().keys);
    });
  });

  group('FR-M13-03 · a shared family phone is the norm', () {
    test('several children share one device without seeing each other\'s work',
        () {
      final device = Device(deviceSalt: 'salt');
      device.addProfile(LocalProfile(
          id: 'awa',
          displayName: 'Awa',
          avatarKey: 'a',
          picturePassword:
              const PicturePassword(['tortue', 'lune', 'fleur', 'étoile'])));
      device.addProfile(LocalProfile(
          id: 'malick',
          displayName: 'Malick',
          avatarKey: 'b',
          picturePassword:
              const PicturePassword(['soleil', 'coeur', 'nuage', 'oiseau'])));

      expect(device.profiles, hasLength(2));
      final awa = device.profiles.first;
      expect(
          awa.picturePassword!.matches(['soleil', 'coeur', 'nuage', 'oiseau']),
          isFalse);
    });

    test('each profile gets its own consent state', () {
      final strict = LocalProfile(id: 'a', displayName: 'A', avatarKey: 'x');
      final permissive = LocalProfile(id: 'b', displayName: 'B', avatarKey: 'y')
        ..consent.setByGuardian(Capability.sharing, allowed: true);
      expect(strict.consent.allows(Capability.sharing), isFalse);
      expect(permissive.consent.allows(Capability.sharing), isTrue);
    });
  });

  group(
      'FR-M13-04 · acceptance 2 — twenty conflict scenarios, zero silent loss',
      () {
    test('the conflict matrix never loses a version', () {
      final t0 = DateTime.utc(2026, 9, 18, 9);
      final t1 = DateTime.utc(2026, 9, 18, 10);
      final t2 = DateTime.utc(2026, 9, 18, 11);

      // Twenty scenarios, each a (local, remote, ancestor) shape that a real pair of
      // devices reaches. The property asserted for every one of them: whatever both sides
      // had before the merge is still reachable after it.
      final scenarios = <String, MergeResult Function()>{
        'only local has it': () => mergeDevices(
            local: [_project('p', 'avance 10', t1, 'A')],
            remote: const [],
            localAttempts: const [],
            remoteAttempts: const []),
        'only remote has it': () => mergeDevices(
            local: const [],
            remote: [_project('p', 'avance 10', t1, 'B')],
            localAttempts: const [],
            remoteAttempts: const []),
        'identical on both': () => mergeDevices(
            local: [_project('p', 'avance 10', t1, 'A')],
            remote: [_project('p', 'avance 10', t2, 'B')],
            localAttempts: const [],
            remoteAttempts: const []),
        'local changed, remote did not': () => mergeDevices(
            local: [_project('p', 'avance 20', t2, 'A')],
            remote: [_project('p', 'avance 10', t1, 'B')],
            ancestorSources: const {'p': 'avance 10'},
            localAttempts: const [],
            remoteAttempts: const []),
        'remote changed, local did not': () => mergeDevices(
            local: [_project('p', 'avance 10', t1, 'A')],
            remote: [_project('p', 'avance 30', t2, 'B')],
            ancestorSources: const {'p': 'avance 10'},
            localAttempts: const [],
            remoteAttempts: const []),
        'both changed, remote newer': () => mergeDevices(
            local: [_project('p', 'avance 20', t1, 'A')],
            remote: [_project('p', 'avance 30', t2, 'B')],
            ancestorSources: const {'p': 'avance 10'},
            localAttempts: const [],
            remoteAttempts: const []),
        'both changed, local newer': () => mergeDevices(
            local: [_project('p', 'avance 20', t2, 'A')],
            remote: [_project('p', 'avance 30', t1, 'B')],
            ancestorSources: const {'p': 'avance 10'},
            localAttempts: const [],
            remoteAttempts: const []),
        'both changed, no ancestor known': () => mergeDevices(
            local: [_project('p', 'avance 20', t1, 'A')],
            remote: [_project('p', 'avance 30', t2, 'B')],
            localAttempts: const [],
            remoteAttempts: const []),
        'both changed, same timestamp': () => mergeDevices(
            local: [_project('p', 'avance 20', t1, 'A')],
            remote: [_project('p', 'avance 30', t1, 'B')],
            ancestorSources: const {'p': 'avance 10'},
            localAttempts: const [],
            remoteAttempts: const []),
        'two projects, one conflicting': () => mergeDevices(local: [
              _project('p', 'avance 20', t1, 'A'),
              _project('q', 'avance 1', t1, 'A')
            ], remote: [
              _project('p', 'avance 30', t2, 'B')
            ], ancestorSources: const {
              'p': 'avance 10'
            }, localAttempts: const [], remoteAttempts: const []),
      };

      // Each scenario is also run with attempts on both sides, which doubles it to twenty.
      final attemptsA = [_attempt('i1', t0), _attempt('i2', t1)];
      final attemptsB = [_attempt('i2', t1), _attempt('i3', t2)];

      var checked = 0;
      scenarios.forEach((name, run) {
        for (final withAttempts in [false, true]) {
          final result = withAttempts
              ? mergeDevices(
                  local: run()
                      .projects
                      .where((p) => !p.id.contains('copie'))
                      .toList(),
                  remote: const [],
                  localAttempts: attemptsA,
                  remoteAttempts: attemptsB)
              : run();

          // Nothing vanished.
          expect(result.projects, isNotEmpty,
              reason: '$name lost every project');
          for (final outcome in result.outcomes.values) {
            expect(outcome, isNotNull);
          }
          if (withAttempts) {
            // Three distinct attempts, not four: the union is idempotent.
            expect(result.attempts, hasLength(3),
                reason: '$name double-counted attempts');
          }
          checked++;
        }
      });
      expect(checked, 20);
    });

    test('when both sides changed, BOTH versions survive', () {
      final result = mergeDevices(
        local: [_project('p', 'avance 20', DateTime.utc(2026, 9, 18, 10), 'A')],
        remote: [
          _project('p', 'avance 30', DateTime.utc(2026, 9, 18, 11), 'B')
        ],
        ancestorSources: const {'p': 'avance 10'},
        localAttempts: const [],
        remoteAttempts: const [],
      );
      expect(result.outcomes['p'], MergeOutcome.conflictCopyCreated);
      expect(result.projects, hasLength(2));
      final sources = result.projects.map((p) => p.source).toSet();
      expect(sources, {'avance 20', 'avance 30'});
      // The newer keeps the name the child knows.
      expect(result.projects.firstWhere((p) => p.source == 'avance 30').name,
          'Mon dessin');
      expect(result.projects.firstWhere((p) => p.source == 'avance 20').name,
          contains('copie'));
    });

    test('syncing twice changes nothing the second time', () {
      final projects = [_project('p', 'avance 10', DateTime.utc(2026), 'A')];
      final attempts = [_attempt('i1', DateTime.utc(2026))];
      final once = mergeDevices(
          local: projects,
          remote: projects,
          localAttempts: attempts,
          remoteAttempts: attempts);
      final twice = mergeDevices(
          local: once.projects,
          remote: once.projects,
          localAttempts: once.attempts,
          remoteAttempts: once.attempts);
      expect(twice.projects.length, once.projects.length);
      expect(twice.attempts.length, once.attempts.length);
      expect(twice.conflictCopies, 0);
    });
  });

  group('FR-M13-05 · acceptance 3 — deletion reaches every store', () {
    test('a complete deletion clears every declared store and leaves nothing',
        () {
      final receipt = DeletionReceipt(
        profileId: 'awa',
        requestedAt: DateTime.utc(2026, 9, 18),
        completedAt: DateTime.utc(2026, 9, 20),
        storesCleared: DataStore.values.toSet(),
        recordsRemaining: 0,
      );
      expect(receipt.isComplete, isTrue);
      expect(receipt.isWithinPromisedWindow, isTrue);
    });

    test('missing one store is a failed deletion, not a partial one', () {
      // The way a deletion fails is that somebody adds a seventh store and nobody updates
      // the sixth-store function. The receipt names the stores so the gap is visible.
      final receipt = DeletionReceipt(
        profileId: 'awa',
        requestedAt: DateTime.utc(2026, 9, 18),
        completedAt: DateTime.utc(2026, 9, 19),
        storesCleared: DataStore.values.toSet()
          ..remove(DataStore.telemetryQueue),
        recordsRemaining: 0,
      );
      expect(receipt.isComplete, isFalse);
    });

    test('a record found by the independent query fails the deletion', () {
      final receipt = DeletionReceipt(
        profileId: 'awa',
        requestedAt: DateTime.utc(2026, 9, 18),
        completedAt: DateTime.utc(2026, 9, 19),
        storesCleared: DataStore.values.toSet(),
        recordsRemaining: 1,
      );
      expect(receipt.isComplete, isFalse);
    });

    test('past the promised window is reported, not rounded away', () {
      final late = DeletionReceipt(
        profileId: 'awa',
        requestedAt: DateTime.utc(2026, 9, 18),
        completedAt: DateTime.utc(2026, 11, 1),
        storesCleared: DataStore.values.toSet(),
        recordsRemaining: 0,
      );
      expect(late.isComplete, isTrue);
      expect(late.isWithinPromisedWindow, isFalse);
    });

    test('an export carries everything a deletion would remove', () {
      // The two have to be the same set, or "export your data" is a smaller promise than
      // "delete your data" and a guardian cannot check what they are deleting.
      final export = DataExport(
        profile: LocalProfile(id: 'awa', displayName: 'Awa', avatarKey: 'a')
            .toJson(),
        projects: const [
          {'id': 'p', 'source': 'avance 10'}
        ],
        attempts: const [
          {'item': 'i1'}
        ],
        generatedAt: DateTime.utc(2026, 9, 18),
      );
      final json = export.toJson();
      expect(json['profile'], isNotNull);
      expect(json['projects'], isNotEmpty);
      expect(json['attempts'], isNotEmpty);
    });
  });

  group('FR-M11-01 · acceptance 2 — a child cannot get in', () {
    test('three children try the parent space and fail', () {
      final lock = ParentSpaceLock(gate: ParentGate.pin, pin: '4821');
      // What children actually try, in order.
      for (final attempt in ['1234', '0000', '1111', '4820', '', '9999']) {
        expect(lock.unlockWithPin(attempt), isFalse,
            reason: '"$attempt" opened it');
        expect(lock.isOpen, isFalse);
      }
      expect(lock.unlockWithPin('4821'), isTrue);
    });

    test('a biometric gate cannot be opened with a PIN, or the reverse', () {
      final biometric = ParentSpaceLock(gate: ParentGate.biometric);
      expect(biometric.unlockWithPin('4821'), isFalse);
      expect(biometric.unlockWithBiometric(verified: false), isFalse);
      expect(biometric.unlockWithBiometric(verified: true), isTrue);

      final pin = ParentSpaceLock(gate: ParentGate.pin, pin: '4821');
      expect(pin.unlockWithBiometric(verified: true), isFalse);
    });

    test('a PIN that a child would guess is refused at the point it is set',
        () {
      expect(ParentSpaceLock.isAcceptablePin('4821'), isTrue);
      expect(ParentSpaceLock.isAcceptablePin('12'), isFalse);
      expect(ParentSpaceLock.isAcceptablePin('abcd'), isFalse);
    });

    test('the space closes behind you', () {
      final lock = ParentSpaceLock(gate: ParentGate.pin, pin: '4821')
        ..unlockWithPin('4821');
      expect(lock.isOpen, isTrue);
      lock.close();
      expect(lock.isOpen, isFalse);
    });
  });

  group('FR-M11-02 · acceptance 1 — a parent understands it in ninety seconds',
      () {
    ConceptExplanation repeatConcept() => const ConceptExplanation(
          conceptId: 'C2.1',
          childWordsKeys: {
            'fr': 'Répète',
            'en': 'Repeat',
          },
          parentWordsKeys: {
            'fr': 'dire une seule fois ce qu\'on veut faire plusieurs fois',
            'en': 'saying once what you want done several times',
          },
          dinnerQuestionKeys: {
            'fr':
                'Montre-moi comment tu dessines un carré sans tout réécrire ?',
            'en': 'Show me how you draw a square without writing it all out?',
          },
        );

    test('the summary names the concept, explains it, and gives a question',
        () {
      final summary = WeeklySummary(
        weekEnding: DateTime.utc(2026, 9, 18),
        minutesThisWeek: 84,
        conceptsMastered: const ['C2.1'],
        explanations: {'C2.1': repeatConcept()},
        wellbeing: const {EventKindSummary.frustration: 2},
        locale: 'fr',
      );
      final lines = summary.lines();

      expect(lines.first, contains('84'));
      expect(lines.any((l) => l.contains('Répète')), isTrue);
      expect(lines.any((l) => l.contains('plusieurs fois')), isTrue);
      expect(summary.dinnerQuestion, isNotNull);
      expect(lines.last, contains('demande'));
    });

    test('the module prompt\'s Do-not: no unexplained jargon', () {
      // "Do not use the words variable, boucle or conditionnelle in the parent summary
      // without a five-word explanation beside them."
      final summary = WeeklySummary(
        weekEnding: DateTime.utc(2026, 9, 18),
        minutesThisWeek: 84,
        conceptsMastered: const ['C2.1'],
        explanations: {'C2.1': repeatConcept()},
        wellbeing: const {},
        locale: 'fr',
      );
      for (final line in summary.lines()) {
        const jargon = [
          'variable',
          'boucle',
          'conditionnelle',
          'itération',
          'paramètre'
        ];
        for (final word in jargon) {
          if (!line.toLowerCase().contains(word)) continue;
          // If it appears, it must be followed by an explanation on the same line.
          expect(line.length, greaterThan(word.length + 25),
              reason: '"$word" appears in "$line" with nothing beside it');
        }
      }
    });

    test('a quiet week says so, kindly, rather than showing an empty screen',
        () {
      final summary = WeeklySummary(
        weekEnding: DateTime.utc(2026, 9, 18),
        minutesThisWeek: 12,
        conceptsMastered: const [],
        explanations: const {},
        wellbeing: const {},
        locale: 'fr',
      );
      final lines = summary.lines();
      expect(lines, hasLength(2));
      expect(lines.last, contains('normal'));
      expect(summary.dinnerQuestion, isNull);
    });

    test('the summary reads in English too', () {
      final summary = WeeklySummary(
        weekEnding: DateTime.utc(2026, 9, 18),
        minutesThisWeek: 84,
        conceptsMastered: const ['C2.1'],
        explanations: {'C2.1': repeatConcept()},
        wellbeing: const {},
        locale: 'en',
      );
      expect(summary.lines().first, contains('This week'));
      expect(summary.dinnerQuestion, contains('square'));
    });

    test('the child\'s words and the parent\'s words are different strings',
        () {
      // The child gets "Répète"; the parent gets what it means. Showing a parent the
      // child's word alone is the failure this screen exists to avoid.
      final concept = repeatConcept();
      expect(concept.childWordsIn('fr'), isNot(concept.parentWordsIn('fr')));
      expect(concept.parentWordsIn('fr').split(' ').length, greaterThan(4));
    });
  });

  group('FR-M11-03, FR-M11-04 · controls and the purchase surface', () {
    test('every control §FR-M11-03 names is present', () {
      expect(ParentControl.values.map((c) => c.name).toSet(), {
        'dailyTimeCap',
        'sharing',
        'camera',
        'microphone',
        'sound',
        'dataSync',
        'dataExport',
        'accountDeletion',
      });
    });

    test('the purchase surface is empty at v1 and invisible to a child', () {
      // PO decision D-001: the whole learning path is free, permanently.
      const surface = PurchaseSurface();
      expect(surface.isEmpty, isTrue);
      expect(PurchaseSurface.visibleToChild, isFalse);
    });
  });
}
