/// Identity (M13, §13).
///
/// `FR-M13-01`: **full functionality without an account.** That is the first rule and it
/// shapes everything else — a local profile is the normal case, an account is an optional
/// addition a guardian makes, and the learning path never asks for either.
///
/// §13's data minimisation is enforced by the type: there is no field for a surname, an
/// address, a photograph or a location, so no screen can collect one.
library;

import 'package:kodo_stage/kodo_stage.dart';

/// A four-symbol picture password (`FR-M13-01`).
///
/// Pictures rather than characters, because the youngest band reads slowly and a
/// seven-character password is a wall. It is a *privacy* control between siblings on a
/// shared phone, not a security boundary, and the type says so rather than implying
/// otherwise with a hash.
class PicturePassword {
  const PicturePassword(this.symbols);

  /// Four of the shipped symbol set, order significant.
  final List<String> symbols;

  static const length = 4;

  /// The symbols a child chooses from. Concrete objects a five-year-old can name, so that
  /// a child can describe their password to a parent without being able to spell.
  static const availableSymbols = [
    'tortue',
    'étoile',
    'lune',
    'fleur',
    'poisson',
    'ballon',
    'arbre',
    'maison',
    'soleil',
    'coeur',
    'nuage',
    'oiseau',
  ];

  bool get isValid =>
      symbols.length == length && symbols.every(availableSymbols.contains);

  bool matches(List<String> attempt) =>
      attempt.length == symbols.length &&
      List.generate(symbols.length, (i) => symbols[i] == attempt[i])
          .every((ok) => ok);
}

/// A child's local profile. No account required, ever.
class LocalProfile {
  LocalProfile({
    required this.id,
    required this.displayName,
    required this.avatarKey,
    this.picturePassword,
    this.locale = 'fr',
    this.birthYear,
    ConsentGate? consent,
  }) : consent = consent ?? ConsentGate();

  /// Device-local. Never leaves the device except as a pseudonym.
  final String id;

  /// A first name or a nickname. **Never a surname** — `FR-M13-05`'s companion in §13 is
  /// explicit, and `FR-M12-05` forbids a surname anywhere in the classroom interface.
  final String displayName;

  final String avatarKey;
  final PicturePassword? picturePassword;
  final String locale;

  /// Only when a guardian created an account, and only the year (§13).
  final int? birthYear;

  final ConsentGate consent;

  /// The fields §13 permits. Anything not here is a finding, and the test below walks the
  /// serialised form to prove nothing else crept in.
  static const permittedFields = {
    'id',
    'displayName',
    'avatarKey',
    'locale',
    'birthYear',
    'picturePassword',
    'consent',
  };

  Map<String, Object?> toJson() => {
        'id': id,
        'displayName': displayName,
        'avatarKey': avatarKey,
        'locale': locale,
        if (birthYear != null) 'birthYear': birthYear,
        if (picturePassword != null)
          'picturePassword': picturePassword!.symbols,
        'consent': consent.toJson(),
      };

  static LocalProfile fromJson(Map<String, Object?> j) => LocalProfile(
        id: j['id']! as String,
        displayName: j['displayName']! as String,
        avatarKey: j['avatarKey']! as String,
        locale: (j['locale'] as String?) ?? 'fr',
        birthYear: j['birthYear'] as int?,
        picturePassword: j['picturePassword'] == null
            ? null
            : PicturePassword(
                (j['picturePassword']! as List<Object?>).cast<String>()),
        consent: ConsentGate.fromJson(
            (j['consent'] as Map<String, Object?>?) ?? const {}),
      );
}

/// Who created an account, and therefore who may change it.
enum GuardianKind { parent, teacher }

/// An optional account, created **only** by a guardian or teacher (`FR-M13-02`).
class Account {
  const Account({
    required this.profileId,
    required this.guardianKind,
    required this.guardianContact,
    required this.createdAt,
    required this.consentRecordedAt,
  });

  final String profileId;
  final GuardianKind guardianKind;

  /// The one piece of adult contact data §13 permits, held for consent. There is no field
  /// for the child's own contact details because a child never has any.
  final String guardianContact;

  final DateTime createdAt;

  /// When verifiable guardian consent was recorded. Null is not representable: an account
  /// that exists without a consent timestamp is the thing §13 forbids.
  final DateTime consentRecordedAt;
}

/// A device that several children share, which §13 calls the norm (`FR-M13-03`).
class Device {
  Device({required this.deviceSalt});

  /// Used to pseudonymise telemetry. Never leaves the device.
  final String deviceSalt;

  final List<LocalProfile> profiles = [];
  final Map<String, Account> accounts = {};

  LocalProfile addProfile(LocalProfile profile) {
    profiles.add(profile);
    return profile;
  }

  /// Creating an account requires a guardian action and a recorded consent moment. There
  /// is no overload without them.
  Account createAccount({
    required String profileId,
    required GuardianKind by,
    required String guardianContact,
    required DateTime consentRecordedAt,
  }) {
    final account = Account(
      profileId: profileId,
      guardianKind: by,
      guardianContact: guardianContact,
      createdAt: consentRecordedAt,
      consentRecordedAt: consentRecordedAt,
    );
    accounts[profileId] = account;
    return account;
  }

  bool hasAccount(String profileId) => accounts.containsKey(profileId);
}
