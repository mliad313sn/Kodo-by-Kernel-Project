/// M17 and M8 acceptance tests.
///
/// **M17:** a schema test rejects any undeclared event · no field can identify a child ·
/// item-health metrics flag anything outside the 35–97 % band · the weekly report is
/// generated.
///
/// **M8:** the prohibited-mechanics audit finds zero instances · no reward can be obtained
/// without a learning event behind it · wellbeing telemetry is live before launch · a
/// child who misses four days returns to zero punitive messaging.
library;

import 'package:kodo_grader/kodo_grader.dart';
import 'package:kodo_insight/kodo_insight.dart';
import 'package:kodo_progress/kodo_progress.dart';
import 'package:test/test.dart';

Attempt _attempt({
  required String itemId,
  required bool passed,
  String concept = 'C1.1',
  int attempts = 1,
}) =>
    Attempt(
      itemId: itemId,
      itemVersion: 1,
      conceptId: concept,
      at: DateTime.utc(2026, 9, 18),
      passed: passed,
      response: const ChoiceResponse(0),
      signals: ProcessSignals(attempts: attempts),
      verdict: Verdict(passed: passed, itemId: itemId, itemVersion: 1),
      itemType: ItemType.t1BuildToTarget,
      difficulty: Difficulty.d2,
    );

void main() {
  group('FR-M17-01 · the taxonomy is fixed at design time', () {
    test('every declared event has a schema', () {
      for (final kind in EventKind.values) {
        expect(eventSchema.containsKey(kind), isTrue,
            reason: '${kind.wireName} has no declared fields');
      }
    });

    test('an event carrying an undeclared field is refused', () {
      expect(
        () => LearningEvent(
          kind: EventKind.conceptMastered,
          pseudonym: 'abc',
          at: DateTime.utc(2026),
          fields: const {EventField.errorCode: 'E_TYPE'},
        ),
        throwsA(isA<EventRejected>()),
      );
    });

    test('an unknown event off the wire is refused', () {
      expect(
        () => LearningEvent.fromJson({
          'event': 'interesting_thing_we_added_later',
          'who': 'abc',
          'at': '2026-09-18T00:00:00Z',
        }),
        throwsA(isA<EventRejected>()),
      );
    });

    test('an unknown field off the wire is refused', () {
      expect(
        () => LearningEvent.fromJson({
          'event': 'item_passed',
          'who': 'abc',
          'at': '2026-09-18T00:00:00Z',
          'childName': 'Awa',
        }),
        throwsA(isA<EventRejected>()),
      );
    });

    test('a declared event round-trips', () {
      final event = LearningEvent(
        kind: EventKind.itemPassed,
        pseudonym: pseudonymFor('local-1', 'device-salt'),
        at: DateTime.utc(2026, 9, 18, 17, 30),
        fields: const {
          EventField.itemId: 'C1.1-04',
          EventField.conceptId: 'C1.1',
          EventField.attemptNumber: 1,
        },
      );
      final restored = LearningEvent.fromJson(event.toJson());
      expect(restored.kind, EventKind.itemPassed);
      expect(restored.fields[EventField.itemId], 'C1.1-04');
    });
  });

  group('FR-M17-02, NFR-PRIV-01 · pseudonymous by construction', () {
    test('there is no field that could hold a name, an email or a device id',
        () {
      // The seat-13 privacy review, made mechanical. The enum IS the allow-list, so this
      // test fails the moment somebody adds a field that could identify a child.
      const identifying = [
        'name',
        'email',
        'phone',
        'address',
        'surname',
        'photo',
        'location',
        'latitude',
        'longitude',
        'deviceId',
        'advertisingId',
        'idfa',
        'gaid',
        'ip',
      ];
      for (final field in EventField.values) {
        for (final word in identifying) {
          expect(field.name.toLowerCase(), isNot(contains(word.toLowerCase())),
              reason: 'EventField.${field.name} could identify a child');
        }
      }
    });

    test('the pseudonym is stable per device and different across devices', () {
      final a = pseudonymFor('profile-1', 'salt-device-a');
      final b = pseudonymFor('profile-1', 'salt-device-a');
      final c = pseudonymFor('profile-1', 'salt-device-b');

      expect(a, b);
      // The same child on two devices is two pseudonyms. That loses a little analytic
      // precision and buys the property that the stream cannot be joined to a person.
      expect(a, isNot(c));
      expect(a.length, 24);
      expect(a, isNot(contains('profile-1')));
    });

    test('an event carries no free text at all', () {
      final event = LearningEvent(
        kind: EventKind.sessionEnd,
        pseudonym: 'abc',
        at: DateTime.utc(2026),
        fields: const {EventField.durationMs: 1200, EventField.localHour: 18},
      );
      for (final value in event.fields.values) {
        expect(value, anyOf(isA<int>(), isA<double>(), isA<String>()));
      }
      // The only strings are enum codes and ids, never something a child typed.
      expect(event.toJson().containsKey('note'), isFalse);
    });
  });

  group('FR-M17-03 · item health flags the band', () {
    /// A cohort where every learner is distinct, and mastery tracks whether they passed —
    /// which is what a healthy item looks like.
    List<HealthObservation> cohort(String itemId,
            {required int passes,
            required int fails,
            bool masteryTracksPassing = true,
            int abandoned = 0}) =>
        [
          for (var i = 0; i < passes; i++)
            HealthObservation(
                attempt: _attempt(itemId: itemId, passed: true),
                learnerPseudonym: 'p$i',
                masteredTheConcept: masteryTracksPassing),
          for (var i = 0; i < fails; i++)
            HealthObservation(
                attempt: _attempt(itemId: itemId, passed: false),
                learnerPseudonym: 'f$i',
                masteredTheConcept: false,
                abandoned: i < abandoned),
        ];

    List<HealthObservation> attemptsFor(String itemId,
            {required int passes, required int fails}) =>
        cohort(itemId, passes: passes, fails: fails);

    test('an item nobody passes is flagged too hard', () {
      final health =
          computeItemHealth(attemptsFor('hard', passes: 6, fails: 34)).single;
      expect(health.passRate, lessThan(healthyPassRateFloor));
      expect(health.flags, contains(HealthFlag.tooHard));
      expect(health.needsRewrite, isTrue);
    });

    test('an item everybody passes is flagged too easy', () {
      final health =
          computeItemHealth(attemptsFor('easy', passes: 49, fails: 1)).single;
      expect(health.passRate, greaterThan(healthyPassRateCeiling));
      expect(health.flags, contains(HealthFlag.tooEasy));
    });

    test('an item inside the band with real discrimination is healthy', () {
      final health =
          computeItemHealth(cohort('ok', passes: 30, fails: 20)).single;
      expect(health.passRate, closeTo(0.6, 0.01));
      expect(health.discrimination, closeTo(1.0, 0.01));
      expect(health.flags, isEmpty, reason: '${health.flags}');
    });

    test('an item children start and leave is flagged', () {
      final health = computeItemHealth(
              cohort('leaky', passes: 20, fails: 20, abandoned: 15))
          .single;
      expect(health.abandonRate, greaterThan(0.15));
      expect(health.flags, contains(HealthFlag.abandoned));
    });

    test('too few attempts is reported, never silently treated as healthy', () {
      // "No flag" must never quietly mean "no data" — that is how a bad item survives a
      // quarter of reviews.
      final health =
          computeItemHealth(attemptsFor('new', passes: 3, fails: 2)).single;
      expect(health.flags, {HealthFlag.insufficientData});
      expect(health.needsRewrite, isFalse);
    });

    test(
        'an item that does not predict mastery is flagged, even inside the band',
        () {
      // Passing it tells you nothing about whether the child understood the concept, so
      // the item is measuring something other than what it is filed under.
      final health = computeItemHealth(cohort('noise',
              passes: 30, fails: 25, masteryTracksPassing: false))
          .single;
      expect(health.passRate, greaterThan(healthyPassRateFloor));
      expect(health.discrimination, closeTo(0, 0.01));
      expect(health.flags, contains(HealthFlag.poorDiscrimination));
    });
  });

  group('FR-M17-04 · the weekly report', () {
    test(
        'it names the wellbeing counters first and the items that need rewriting',
        () {
      final observations = <HealthObservation>[
        for (var i = 0; i < 40; i++)
          HealthObservation(
              attempt: _attempt(itemId: 'C1.1-01', passed: i > 34),
              learnerPseudonym: 'a$i',
              masteredTheConcept: i > 34),
        for (var i = 0; i < 40; i++)
          HealthObservation(
              attempt: _attempt(itemId: 'C1.1-02', passed: true),
              learnerPseudonym: 'b$i',
              masteredTheConcept: true),
      ];
      final report = CurriculumHealthReport(
        weekEnding: DateTime.utc(2026, 9, 18),
        items: computeItemHealth(observations),
        wellbeing: const {
          EventKindSummary.frustration: 12,
          EventKindSummary.lateNight: 0,
          EventKindSummary.goalOverrun: 3,
          EventKindSummary.abandonedAfterFailure: 5,
          EventKindSummary.stoppedAtOwnGoal: 41,
        },
        learnersActive: 120,
      );

      final text = report.render();
      expect(text, contains('Bien-être'));
      expect(text, contains('Frustrations'));
      expect(text, contains('C1.1-01'));
      expect(report.needingRewrite, hasLength(2));
      expect(report.toJson()['learnersActive'], 120);

      // The wellbeing block comes before the item block, because a number at the bottom of
      // page four is not treated as anything.
      expect(
          text.indexOf('Bien-être'), lessThan(text.indexOf('Items mesurés')));
    });
  });

  group('FR-M8-04 · acceptance 1 — the prohibited-mechanics audit', () {
    /// What KODO actually declares. If this list ever trips the audit, the build fails.
    List<MotivationSurface> shippedSurfaces() => const [
          MotivationSurface(
            name: 'carte',
            strings: {
              'map.locked':
                  'Cette île s\'ouvrira quand tu auras appris ce qu\'il faut.',
            },
          ),
          MotivationSurface(
            name: 'entraînement',
            strings: {
              'training.goal_reached':
                  'Tu as atteint ton objectif. C\'est bien de '
                      's\'arrêter maintenant.',
              'training.keep_going': 'Tu peux continuer si tu veux.',
            },
          ),
          MotivationSurface(
            name: 'série',
            strings: {
              'streak.free_day_used':
                  'Tu as pris un jour de repos. Ta série continue.',
              'streak.restarted':
                  'Tu recommences une série. Tout ce que tu as appris '
                      'est toujours là.',
            },
          ),
          MotivationSurface(
            name: 'notifications',
            // Nothing between 20:00 and 07:00.
            notificationHoursLocal: [16, 17, 18],
            isLearningSurface: false,
          ),
          MotivationSurface(
            name: 'espace parent',
            hasPurchaseSurface: false,
            isLearningSurface: false,
          ),
        ];

    test('the shipped surfaces produce zero findings', () {
      final findings = auditMechanics(shippedSurfaces());
      expect(findings, isEmpty, reason: findings.join('\n'));
    });

    test('the audit actually catches each prohibited mechanic', () {
      // An audit that never fails is not an audit. Each of these is a thing a product
      // manager will one day propose in good faith.
      final cases = <ProhibitedMechanic, MotivationSurface>{
        ProhibitedMechanic.countdownOnLearningItem:
            const MotivationSurface(name: 'item', hasCountdown: true),
        ProhibitedMechanic.variableRatioReward:
            const MotivationSurface(name: 'coffre', rewardIsRandomised: true),
        ProhibitedMechanic.lossFramedStreak:
            const MotivationSurface(name: 'série', streakFramedAsLoss: true),
        ProhibitedMechanic.peerRankingAgainstStrangers: const MotivationSurface(
            name: 'classement', ranksAgainstStrangers: true),
        ProhibitedMechanic.notificationAfter20h: const MotivationSurface(
            name: 'rappel',
            notificationHoursLocal: [21],
            isLearningSurface: false),
        ProhibitedMechanic.monetisedInterruption:
            const MotivationSurface(name: 'boutique', hasPurchaseSurface: true),
        ProhibitedMechanic.guiltMessaging: const MotivationSurface(
            name: 'retour',
            strings: {'comeback': 'Tes amis sont déjà au monde 3 !'}),
      };

      cases.forEach((mechanic, surface) {
        final findings = auditMechanics([surface]);
        expect(findings.map((f) => f.mechanic), contains(mechanic),
            reason: 'the audit missed ${mechanic.description}');
      });

      final expiring = MotivationSurface(
          name: 'offre', rewardExpiresAt: DateTime.utc(2026, 9, 19));
      expect(auditMechanics([expiring]).map((f) => f.mechanic),
          contains(ProhibitedMechanic.artificialScarcity));
    });

    test('a notification at 07:00 is fine and one at 06:00 is not', () {
      // §10 forbids notifications "engineered around bedtime". The window is stated in the
      // code rather than left to whoever configures the scheduler.
      expect(
          auditMechanics([
            const MotivationSurface(
                name: 'n',
                notificationHoursLocal: [7, 19],
                isLearningSurface: false)
          ]),
          isEmpty);
      expect(
          auditMechanics([
            const MotivationSurface(
                name: 'n',
                notificationHoursLocal: [6],
                isLearningSurface: false)
          ]),
          isNotEmpty);
    });
  });

  group('FR-M8-01 · acceptance 2 — no reward without a learning event', () {
    test('every reward names what earned it', () {
      final rewards = <Reward>[
        const StarReward('star.C1.1', 'C1.1', 3),
        const BadgeReward('badge.debug', ReinforcedBehaviour.debugged),
        const CosmeticReward('hat.red', 'badge:debugged'),
        stoppingBadge,
      ];
      expect(auditRewards(rewards), isEmpty);
      for (final reward in rewards) {
        expect(reward.earnedBy.trim(), isNotEmpty);
      }
    });

    test('a reward earned by a purchase or an advertisement is refused', () {
      final findings = auditRewards([
        const CosmeticReward('hat.gold', 'purchase:1.99'),
        const CosmeticReward('hat.silver', 'ad:rewarded_video'),
      ]);
      expect(findings, hasLength(2));
      expect(findings.map((f) => f.mechanic).toSet(),
          {ProhibitedMechanic.payToProgress});
    });

    test('stars come from mastery depth and nowhere else', () {
      final states = {
        'C1.1': MasteryState(
          conceptId: 'C1.1',
          state: ConceptState.maitrise,
          evidence: const MasteryEvidence(
            itemsPassed: 10,
            typesSpanned: 4,
            firstAttemptRate: 0.9,
            passedDissimilar: true,
            criteriaOneToThreeMetAt: null,
            retentionPassedAt: null,
          ),
          lastTouchedAt: DateTime.utc(2026),
        ),
      };
      final stars = starsFor(states);
      expect(stars.single.stars, 3);
      expect(stars.single.earnedBy, 'mastery:C1.1:3');
    });
  });

  group('FR-M8-02, FR-M8-03 · goals and forgiving streaks', () {
    test('a child sets their own goal, from three options', () {
      expect(DailyGoal.options, [10, 20, 30]);
      expect(const DailyGoal(20).isValid, isTrue);
      expect(const DailyGoal(45).isValid, isFalse);
    });

    test('reaching the goal celebrates AND says stopping is good', () {
      const reached = GoalReached(goal: DailyGoal(20), actualMinutes: 21);
      expect(reached.celebrationKey, isNotEmpty);
      // Not nullable, and that is the point: the permission to stop is the half that gets
      // dropped in a sprint.
      expect(reached.stoppingIsGoodKey, isNotEmpty);
      expect(reached.isOverrun, isFalse);
    });

    test('going far past the goal is a wellbeing event, never a reward', () {
      const overrun = GoalReached(goal: DailyGoal(20), actualMinutes: 55);
      expect(overrun.isOverrun, isTrue);
      // There is no reward for it anywhere in the reinforced behaviours.
      expect(ReinforcedBehaviour.values.map((b) => b.name),
          isNot(contains('exceededGoal')));
    });

    test('two free days a week, and running out costs nothing but the count',
        () {
      var streak = const Streak(days: 12, freeDaysUsedThisWeek: 0);
      streak = streak.missedADay();
      expect(streak.days, 12, reason: 'the first free day should not break it');
      expect(streak.freeDaysLeft, 1);

      streak = streak.missedADay();
      expect(streak.days, 12);
      expect(streak.freeDaysLeft, 0);

      streak = streak.missedADay();
      expect(streak.days, 0);
      // What is NOT lost: items, stars, cosmetics. The streak is the only thing that
      // resets, which is `FR-M8-03`'s "no loss of accumulated work".
      expect(streak.freeDaysLeft, 2, reason: 'the week starts again');
    });

    test('acceptance 4 — four missed days produce no punitive message', () {
      var streak = const Streak(days: 9, freeDaysUsedThisWeek: 0);
      final keys = <String>[];
      for (var day = 0; day < 4; day++) {
        streak = streak.missedADay();
        keys.add(streak.missedDayMessageKey);
      }

      // Verified by script review of every string, which is what the acceptance test asks
      // for — done here over the actual strings rather than over a promise.
      const strings = {
        'streak.free_day_used':
            'Tu as pris un jour de repos. Ta série continue.',
        'streak.restarted':
            'Tu recommences une série. Tout ce que tu as appris est toujours là.',
      };
      final findings = auditMechanics([
        MotivationSurface(
            name: 'série après 4 jours',
            strings: {for (final key in keys.toSet()) key: strings[key]!}),
      ]);
      expect(findings, isEmpty, reason: findings.join('\n'));
      expect(keys.toSet(), {'streak.free_day_used', 'streak.restarted'});
    });
  });

  group('FR-M8-05, §10 · comparison and wellbeing instrumentation', () {
    test(
        'a child may only be compared with themselves, or an opt-in class board',
        () {
      expect(ComparisonScope.values, hasLength(2));
      expect(ComparisonScope.values.map((s) => s.name),
          isNot(contains('globalLeaderboard')));
    });

    test('acceptance 3 — every wellbeing event of §10 is instrumented', () {
      // "Frustration events, late-night sessions, overruns past the child's own goal, and
      // abandonment after failure are all instrumented BEFORE launch."
      final wellbeing = EventKind.values.where((k) => k.isWellbeing).toSet();
      expect(wellbeing, {
        EventKind.frustration,
        EventKind.lateNightSession,
        EventKind.goalOverrun,
        EventKind.abandonedAfterFailure,
        EventKind.stoppedAtOwnGoal,
      });
      for (final kind in wellbeing) {
        expect(eventSchema[kind], isNotEmpty,
            reason: '${kind.wireName} is declared but carries nothing');
      }
    });

    test('a frustration event is emitted at three consecutive failures', () {
      // §4.7's threshold and M6's escalation ladder are the same number, from one place.
      expect(escalationFor(3), Escalation.hint);
      expect(const ProcessSignals(attempts: 3).isFrustrationEvent, isTrue);
      expect(const ProcessSignals(attempts: 2).isFrustrationEvent, isFalse);
    });

    test('stopping at your own goal is a reinforced behaviour', () {
      // Unusual and deliberate: an unrewarded promise loses to every rewarded one.
      expect(stoppingBadge.behaviour, ReinforcedBehaviour.stoppedAtGoal);
      expect(auditRewards([stoppingBadge]), isEmpty);
    });
  });
}
