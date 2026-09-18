/// The motivation system (M8, §10).
///
/// *"You are making a child want to come back tomorrow, using competence rather than
/// compulsion."*
///
/// The brief asked for something *ludique et addictive*. §10 accepts the intent — sustained
/// voluntary return — and then refuses the mechanic, because *"addictive as a mechanic and
/// addictive as an outcome are different products"*. `FR-M8-04` lists what is prohibited
/// and makes it **auditable at G4**, so the audit is written here as code and runs in CI
/// rather than being a checklist somebody walks once a quarter.
library;

import 'package:kodo_progress/kodo_progress.dart';

/// Something a child can earn.
sealed class Reward {
  const Reward(this.id);
  final String id;

  /// Every reward names the learning event behind it. `FR-M8-01` — rewards are
  /// competence-linked — is enforced by there being no constructor without one.
  String get earnedBy;
}

/// Stars, tied to mastery depth (`FR-M7-06`).
class StarReward extends Reward {
  const StarReward(super.id, this.conceptId, this.stars);
  final String conceptId;
  final int stars;

  @override
  String get earnedBy => 'mastery:$conceptId:$stars';
}

/// A badge for a behaviour worth reinforcing.
class BadgeReward extends Reward {
  const BadgeReward(super.id, this.behaviour);
  final ReinforcedBehaviour behaviour;

  @override
  String get earnedBy => 'behaviour:${behaviour.name}';
}

/// A cosmetic for Tika or the stage. **Earned only** (`FR-M8-01`).
class CosmeticReward extends Reward {
  const CosmeticReward(super.id, this.unlockedBy);

  /// The badge or mastery that unlocked it. There is no `price` field and no
  /// `unlockWithAd` constructor, which is how `FR-M7-07` is kept.
  final String unlockedBy;

  @override
  String get earnedBy => unlockedBy;
}

/// The behaviours §FR-M8-01 says to reinforce. Note what is not here: speed, streak
/// length, and doing more than your goal.
enum ReinforcedBehaviour {
  /// Found and fixed a bug.
  debugged,

  /// Made a working program shorter.
  shortened,

  /// Finished a project.
  finishedProject,

  /// Helped someone by sharing a remix.
  helpedByRemix,

  /// Came back to a concept marked À revoir.
  returnedToReview,

  /// Stopped at their own goal. Reinforcing *stopping* is unusual and deliberate: §10's
  /// *"c'est bien de s'arrêter maintenant"* is a promise, and a promise with no reward
  /// behind it loses to every reward that is.
  stoppedAtGoal,
}

/// A child's daily goal, which they set themselves (`FR-M8-02`).
class DailyGoal {
  const DailyGoal(this.minutes);

  /// Ten, twenty or thirty. Not a number the product picks, and not one it nudges upward.
  final int minutes;

  static const options = [10, 20, 30];

  bool get isValid => options.contains(minutes);
}

/// A forgiving streak (`FR-M8-03`).
///
/// *"two free days per week, no loss of accumulated items, never a red warning."* The
/// class models the forgiveness rather than leaving it to the interface, because a streak
/// that is punitive in the data model will eventually be punitive on screen.
class Streak {
  const Streak({required this.days, required this.freeDaysUsedThisWeek});

  final int days;
  final int freeDaysUsedThisWeek;

  static const freeDaysPerWeek = 2;

  int get freeDaysLeft =>
      (freeDaysPerWeek - freeDaysUsedThisWeek).clamp(0, freeDaysPerWeek);

  /// A missed day. The streak survives while free days remain, and when they run out it
  /// **resets to zero without taking anything else** — no items, no stars, no cosmetics.
  Streak missedADay() => freeDaysLeft > 0
      ? Streak(days: days, freeDaysUsedThisWeek: freeDaysUsedThisWeek + 1)
      : const Streak(days: 0, freeDaysUsedThisWeek: 0);

  Streak anotherDay() =>
      Streak(days: days + 1, freeDaysUsedThisWeek: freeDaysUsedThisWeek);

  /// The message key for a missed day. There is no key here that blames anybody, and the
  /// audit below checks that.
  String get missedDayMessageKey =>
      freeDaysLeft > 0 ? 'streak.free_day_used' : 'streak.restarted';
}

/// What the child may compare themselves against (`FR-M8-05`).
enum ComparisonScope {
  /// The child versus their own past. Always available.
  ownPast,

  /// An opt-in, teacher-mediated class board of **effort**, not speed.
  classEffortOptIn,
}

// ---------------------------------------------------------------------------------------
// The prohibited-mechanics audit (FR-M8-04, §10, and the M8 acceptance test)
// ---------------------------------------------------------------------------------------

/// A mechanic §10 forbids.
enum ProhibitedMechanic {
  countdownOnLearningItem('a countdown on a learning item'),
  variableRatioReward('a randomised reward box'),
  lossFramedStreak('a streak framed as a loss'),
  peerRankingAgainstStrangers('a leaderboard against strangers'),
  notificationAfter20h('a notification after 20:00 local time'),
  monetisedInterruption('a monetised interruption'),
  artificialScarcity('artificial scarcity'),
  guiltMessaging('guilt messaging'),
  payToProgress('progress that can be bought');

  const ProhibitedMechanic(this.description);
  final String description;
}

/// Something the audit found.
class MechanicFinding {
  const MechanicFinding(this.mechanic, this.where, this.evidence);
  final ProhibitedMechanic mechanic;
  final String where;
  final String evidence;

  @override
  String toString() => '[${mechanic.name}] $where: $evidence';
}

/// What the audit is given to look at.
///
/// It inspects *declared configuration and strings*, which is what a seat-5, seat-6 and
/// seat-13 audit can actually inspect. It cannot prove the absence of a mechanic nobody
/// declared — no static check can — and the G4 protocol pairs it with a human pass for
/// exactly that reason.
class MotivationSurface {
  const MotivationSurface({
    required this.name,
    this.hasCountdown = false,
    this.rewardIsRandomised = false,
    this.streakFramedAsLoss = false,
    this.ranksAgainstStrangers = false,
    this.notificationHoursLocal = const [],
    this.hasPurchaseSurface = false,
    this.rewardExpiresAt,
    this.strings = const {},
    this.isLearningSurface = true,
  });

  final String name;
  final bool hasCountdown;
  final bool rewardIsRandomised;
  final bool streakFramedAsLoss;
  final bool ranksAgainstStrangers;
  final List<int> notificationHoursLocal;
  final bool hasPurchaseSurface;

  /// A reward that disappears if you do not claim it is artificial scarcity.
  final DateTime? rewardExpiresAt;

  /// Child-facing strings, keyed. Audited for guilt.
  final Map<String, String> strings;

  final bool isLearningSurface;
}

/// Words that blame a child for not showing up.
///
/// Authored as a list rather than a regular expression because the audit's output has to
/// be arguable: a reviewer needs to see which word tripped it and be able to say "that one
/// is fine in this sentence".
const _guiltWords = [
  'tu as perdu',
  'you lost',
  'tu as raté',
  'you failed',
  'ne déçois pas',
  "don't let",
  'dernière chance',
  'last chance',
  'tu abandonnes',
  'giving up',
  'tes amis sont',
  'your friends are',
  'tu es en retard',
  "you're behind",
  'reviens vite',
  'come back quickly',
  'on t\'attend',
  'we miss you',
];

/// Runs the audit. An empty list is the only passing result.
///
/// This is the M8 acceptance test: *"a prohibited-mechanics audit (seat 5 + seat 6 +
/// seat 13) finds zero instances"*. Writing it as code does not replace those three
/// people; it means they arrive at G4 to review a list rather than to build one.
List<MechanicFinding> auditMechanics(Iterable<MotivationSurface> surfaces) {
  final findings = <MechanicFinding>[];

  for (final surface in surfaces) {
    if (surface.hasCountdown && surface.isLearningSurface) {
      findings.add(MechanicFinding(ProhibitedMechanic.countdownOnLearningItem,
          surface.name, 'declares a countdown'));
    }
    if (surface.rewardIsRandomised) {
      findings.add(MechanicFinding(ProhibitedMechanic.variableRatioReward,
          surface.name, 'declares a randomised reward'));
    }
    if (surface.streakFramedAsLoss) {
      findings.add(MechanicFinding(ProhibitedMechanic.lossFramedStreak,
          surface.name, 'frames the streak as something lost'));
    }
    if (surface.ranksAgainstStrangers) {
      findings.add(MechanicFinding(
          ProhibitedMechanic.peerRankingAgainstStrangers,
          surface.name,
          'ranks children against strangers'));
    }
    for (final hour in surface.notificationHoursLocal) {
      if (hour >= 20 || hour < 7) {
        findings.add(MechanicFinding(
            ProhibitedMechanic.notificationAfter20h,
            surface.name,
            'sends a notification at ${hour.toString().padLeft(2, '0')}:00 local'));
      }
    }
    if (surface.hasPurchaseSurface) {
      findings.add(MechanicFinding(ProhibitedMechanic.monetisedInterruption,
          surface.name, 'shows a purchase surface to a child'));
    }
    if (surface.rewardExpiresAt != null) {
      findings.add(MechanicFinding(ProhibitedMechanic.artificialScarcity,
          surface.name, 'a reward that expires'));
    }
    for (final entry in surface.strings.entries) {
      final lower = entry.value.toLowerCase();
      for (final word in _guiltWords) {
        if (lower.contains(word)) {
          findings.add(MechanicFinding(ProhibitedMechanic.guiltMessaging,
              surface.name, '"${entry.key}" says "${entry.value}"'));
          break;
        }
      }
    }
  }
  return findings;
}

/// Checks that nothing in the progression can be bought (`FR-M7-07`, `FR-M8-04`).
///
/// Given the rewards a build declares, every one must name a learning event behind it.
List<MechanicFinding> auditRewards(Iterable<Reward> rewards) => [
      for (final reward in rewards)
        if (reward.earnedBy.trim().isEmpty ||
            reward.earnedBy.startsWith('purchase') ||
            reward.earnedBy.startsWith('ad'))
          MechanicFinding(ProhibitedMechanic.payToProgress, reward.id,
              'earned by "${reward.earnedBy}"'),
    ];

/// The end-of-goal moment (`FR-M8-02`).
///
/// *"a gentle end-of-goal celebration and an explicit 'c'est bien de s'arrêter'."* The
/// second half is the part that is easy to drop in a sprint, so it is returned as a
/// required field rather than an optional one.
class GoalReached {
  const GoalReached({required this.goal, required this.actualMinutes});
  final DailyGoal goal;
  final int actualMinutes;

  /// The celebration.
  String get celebrationKey => 'goal.reached';

  /// The permission to stop. Not nullable.
  String get stoppingIsGoodKey => 'goal.stopping_is_good';

  /// True once the child has gone well past what they set themselves. It produces a
  /// wellbeing event, never a reward.
  bool get isOverrun => actualMinutes > goal.minutes * 2;
}

/// The reward a child gets for stopping when they said they would.
///
/// It exists because §10 makes *"c'est bien de s'arrêter maintenant"* a promise, and an
/// unrewarded promise loses to every rewarded one.
const stoppingBadge =
    BadgeReward('badge.stopped_at_goal', ReinforcedBehaviour.stoppedAtGoal);

/// Stars a concept has earned, for the map.
List<StarReward> starsFor(Map<String, MasteryState> states) => [
      for (final entry in states.entries)
        if (entry.value.stars > 0)
          StarReward('star.${entry.key}', entry.key, entry.value.stars),
    ];
