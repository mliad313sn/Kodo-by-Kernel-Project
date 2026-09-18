/// Classroom mode (M12).
///
/// *"You are building for a teacher with thirty-five pupils, one hour a week, and no
/// internet."* Every design decision here follows from that sentence, and the one that
/// follows hardest is `FR-M12-03`: the classroom works with **no internet at all**, seeded
/// from a teacher's device over a local hotspot or from an SD card.
///
/// Two rules from the module prompt's `Do not` are enforced by the types: no pupil email
/// address, and no child's surname anywhere in the classroom interface.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:kodo_progress/kodo_progress.dart';

/// A pupil, as the classroom knows them.
///
/// **First name only** (`FR-M12-01`). There is no surname field and no email field, so the
/// module prompt's two `Do not`s are not rules a screen has to remember.
class Pupil {
  const Pupil({required this.id, required this.firstName, required this.joinedAt});

  final String id;
  final String firstName;
  final DateTime joinedAt;

  /// What a teacher sees when two children share a first name.
  ///
  /// A teacher's instinct here is the surname initial, and the module prompt forbids it:
  /// *"do not put any child's surname anywhere in the classroom UI"*, and the CMS does not
  /// hold one to put there. So the disambiguator is the order they joined, which the
  /// teacher can read off the same screen. A child with no clash keeps a bare first name;
  /// nobody is numbered just in case.
  String displayNameAmong(Iterable<Pupil> others) {
    final sharing = [
      for (final p in others)
        if (p.firstName == firstName) p,
      if (!others.any((p) => p.id == id)) this,
    ]..sort((a, b) {
        final byTime = a.joinedAt.compareTo(b.joinedAt);
        return byTime != 0 ? byTime : a.id.compareTo(b.id);
      });
    if (sharing.length <= 1) return firstName;
    return '$firstName (${sharing.indexWhere((p) => p.id == id) + 1})';
  }
}

/// A class code a teacher reads out loud.
///
/// Six characters from an alphabet with no `0/O`, `1/I/L` or `5/S`, because the code is
/// read across a room to thirty-five children and every ambiguous glyph is a hand going
/// up. It is not a secret: joining also needs the teacher to have the class open.
class ClassCode {
  const ClassCode(this.value);

  static const alphabet = 'ABCDEFGHJKMNPQRTUVWXY23479';
  static const length = 6;

  final String value;

  bool get isValid =>
      value.length == length && value.split('').every(alphabet.contains);

  /// Deterministic from a seed, so a test and a teacher see the same code.
  static ClassCode fromSeed(int seed) {
    var state = seed == 0 ? 1 : seed;
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      state = (state * 1103515245 + 12345) & 0x7FFFFFFF;
      buffer.write(alphabet[state % alphabet.length]);
    }
    return ClassCode(buffer.toString());
  }
}

/// What a teacher assigned, and by when.
class Assignment {
  const Assignment({
    required this.id,
    required this.scope,
    required this.targetIds,
    required this.dueOn,
  });

  final String id;
  final AssignmentScope scope;

  /// World numbers, concept ids or item ids, depending on [scope].
  final List<String> targetIds;

  final DateTime dueOn;
}

enum AssignmentScope { world, concept, itemSet }

/// One cell of the mastery grid (`FR-M12-02`).
class GridCell {
  const GridCell(this.pupilId, this.conceptId, this.state, this.stars);
  final String pupilId;
  final String conceptId;
  final ConceptState state;
  final int stars;
}

/// A class.
class Classroom {
  Classroom({
    required this.id,
    required this.name,
    required this.code,
    required this.teacherName,
  });

  final String id;
  final String name;
  final ClassCode code;
  final String teacherName;

  final List<Pupil> pupils = [];
  final List<Assignment> assignments = [];

  /// Joining needs the code and a first name. Nothing else — no email, no password, no
  /// parental email address, because a class of thirty-five cannot wait for thirty-five
  /// inboxes.
  Pupil join({required String firstName, required ClassCode using, required DateTime at}) {
    if (using.value != code.value) {
      throw ArgumentError('wrong class code');
    }
    final pupil = Pupil(
      id: 'pupil-${pupils.length + 1}-${firstName.toLowerCase()}',
      firstName: firstName,
      joinedAt: at,
    );
    pupils.add(pupil);
    return pupil;
  }

  /// The live grid of pupil × concept.
  List<GridCell> grid(Map<String, Map<String, MasteryState>> statesByPupil,
      List<String> conceptIds) {
    return [
      for (final pupil in pupils)
        for (final conceptId in conceptIds)
          GridCell(
            pupil.id,
            conceptId,
            statesByPupil[pupil.id]?[conceptId]?.state ?? ConceptState.nonVu,
            statesByPupil[pupil.id]?[conceptId]?.stars ?? 0,
          ),
    ];
  }
}

// ---------------------------------------------------------------------------------------
// Offline seeding (FR-M12-03) — the part that has to work in a room with no internet
// ---------------------------------------------------------------------------------------

/// A bundle a teacher device hands to a pupil device.
class SeedBundle {
  const SeedBundle({
    required this.worlds,
    required this.payload,
    required this.checksum,
    required this.bytes,
  });

  final List<int> worlds;

  /// The content packs, serialised.
  final String payload;

  /// SHA-256 of [payload]. `IMP-008` asks for *"SD-card and USB pack sideloading with a
  /// checksum verification screen"* — a screen a teacher can look at and believe, which
  /// means the checksum has to be computed on the receiving device, not asserted by the
  /// sender.
  final String checksum;

  /// How many bytes actually cross the wire or the card.
  ///
  /// Not necessarily `payload.length`: a real bundle is a manifest plus a media directory,
  /// exactly as `PackManifest` already describes a `ContentPack`. [payload] is what the
  /// checksum covers; [bytes] is the size of what it describes. [of] is the convenience for
  /// the case where the payload *is* the whole bundle.
  final int bytes;

  static SeedBundle of(List<int> worlds, String payload) => SeedBundle(
        worlds: worlds,
        payload: payload,
        checksum: sha256.convert(utf8.encode(payload)).toString(),
        bytes: utf8.encode(payload).length,
      );

  /// What the verification screen shows. Recomputed here, never trusted from the bundle.
  bool verifies() =>
      sha256.convert(utf8.encode(payload)).toString() == checksum;
}

/// How a bundle reached the device.
enum SeedTransport {
  /// A local hotspot from the teacher's device.
  hotspot,

  /// An SD card.
  sdCard,

  /// A USB stick.
  usb,
}

/// The result of seeding one device.
class SeedOutcome {
  const SeedOutcome({
    required this.deviceId,
    required this.transport,
    required this.accepted,
    required this.seconds,
    this.refusedBecause,
  });

  final String deviceId;
  final SeedTransport transport;
  final bool accepted;
  final double seconds;

  /// A message key, never a sentence — the teacher's screen is localised like everything
  /// else.
  final String? refusedBecause;
}

/// Seeds a set of devices and reports how long it took.
///
/// The M12 acceptance test is a **no-internet drill: 35 devices seeded and collected in
/// under 20 minutes.** The model exists so the drill can be rehearsed against measured
/// throughput before thirty-five real tablets are in a room.
class ClassroomSeeder {
  const ClassroomSeeder({
    this.hotspotBytesPerSecond = 2 * 1024 * 1024,
    this.sdCardBytesPerSecond = 20 * 1024 * 1024,
    this.usbBytesPerSecond = 15 * 1024 * 1024,
    this.perDeviceOverheadSeconds = 4,
  });

  /// A classroom hotspot shared by many devices, not a laboratory figure. `IMP-008`
  /// records that one hotspot for thirty-five devices was measured as too slow, which is
  /// why the model takes contention into account below.
  final int hotspotBytesPerSecond;
  final int sdCardBytesPerSecond;
  final int usbBytesPerSecond;
  final double perDeviceOverheadSeconds;

  List<SeedOutcome> seed({
    required SeedBundle bundle,
    required List<String> deviceIds,
    required SeedTransport transport,
  }) {
    final outcomes = <SeedOutcome>[];
    for (var i = 0; i < deviceIds.length; i++) {
      final verified = bundle.verifies();
      final rate = switch (transport) {
        // A hotspot is shared, so the more devices, the slower each one gets. Modelling it
        // as a constant is how a drill passes on paper and fails in a classroom.
        SeedTransport.hotspot =>
          hotspotBytesPerSecond / (1 + deviceIds.length / 8),
        SeedTransport.sdCard => sdCardBytesPerSecond.toDouble(),
        SeedTransport.usb => usbBytesPerSecond.toDouble(),
      };
      outcomes.add(SeedOutcome(
        deviceId: deviceIds[i],
        transport: transport,
        accepted: verified,
        seconds: verified ? bundle.bytes / rate + perDeviceOverheadSeconds : 0,
        refusedBecause: verified ? null : 'seed.checksum_mismatch',
      ));
    }
    return outcomes;
  }

  /// Wall-clock time for the seeding half of the drill. Hotspot seeding runs in parallel;
  /// a card is carried from device to device, so it is serial.
  Duration drillDuration(List<SeedOutcome> outcomes, SeedTransport transport) {
    if (outcomes.isEmpty) return Duration.zero;
    final seconds = transport == SeedTransport.hotspot
        ? outcomes.map((o) => o.seconds).reduce((a, b) => a > b ? a : b)
        : outcomes.fold<double>(0, (sum, o) => sum + o.seconds);
    return Duration(milliseconds: (seconds * 1000).round());
  }

  /// Collects progress back from the devices.
  ///
  /// The acceptance test is *"35 devices seeded **and collected** in under 20 minutes"*,
  /// so the drill is not over when the content has landed. Collection is the other
  /// direction and it does not behave like seeding: one teacher device is the sink, so
  /// the transfers queue behind each other rather than running in parallel.
  List<CollectOutcome> collect({
    required List<String> deviceIds,
    required int bytesPerDevice,
    required SeedTransport transport,
  }) {
    final rate = switch (transport) {
      SeedTransport.hotspot => hotspotBytesPerSecond / (1 + deviceIds.length / 8),
      SeedTransport.sdCard => sdCardBytesPerSecond.toDouble(),
      SeedTransport.usb => usbBytesPerSecond.toDouble(),
    };
    return [
      for (final deviceId in deviceIds)
        CollectOutcome(
          deviceId: deviceId,
          bytes: bytesPerDevice,
          seconds: bytesPerDevice / rate + perDeviceOverheadSeconds,
        ),
    ];
  }

  /// Wall-clock time for collection: serial, because the teacher's device is the one
  /// every pupil device is talking to.
  Duration collectionDuration(List<CollectOutcome> outcomes) => Duration(
      milliseconds:
          (outcomes.fold<double>(0, (sum, o) => sum + o.seconds) * 1000).round());

  /// The whole no-internet drill: seed everybody, then collect from everybody.
  Duration wholeDrill({
    required SeedBundle bundle,
    required List<String> deviceIds,
    required SeedTransport transport,
    required int progressBytesPerDevice,
  }) {
    final seeded = seed(bundle: bundle, deviceIds: deviceIds, transport: transport);
    final collected = collect(
      deviceIds: deviceIds,
      bytesPerDevice: progressBytesPerDevice,
      transport: transport,
    );
    return drillDuration(seeded, transport) + collectionDuration(collected);
  }
}

/// One pupil device's progress, collected.
class CollectOutcome {
  const CollectOutcome({
    required this.deviceId,
    required this.bytes,
    required this.seconds,
  });
  final String deviceId;
  final int bytes;
  final double seconds;
}

// ---------------------------------------------------------------------------------------
// Printables (FR-M12-04) and projection (FR-M12-05)
// ---------------------------------------------------------------------------------------

/// A printable A4 progress sheet.
///
/// The acceptance test is *"legible in monochrome on a low-toner printer"*, so the sheet is
/// built from **characters, not colour**: a concept's state is a glyph a child or parent
/// can read after the toner has given up.
class ProgressSheet {
  const ProgressSheet({required this.className, required this.rows, required this.conceptIds});

  final String className;
  final List<GridCell> rows;
  final List<String> conceptIds;

  /// The monochrome glyphs. Never colour, never a filled circle that becomes a grey blob.
  static const glyphs = {
    ConceptState.nonVu: '.',
    ConceptState.decouvert: 'o',
    ConceptState.enCours: '/',
    ConceptState.maitrise: '#',
    ConceptState.aRevoir: '~',
  };

  static const legend = {
    'fr': {
      '.': 'pas encore vu',
      'o': 'découvert',
      '/': 'en cours',
      '#': 'maîtrisé',
      '~': 'à revoir',
    },
    'en': {
      '.': 'not seen yet',
      'o': 'discovered',
      '/': 'in progress',
      '#': 'mastered',
      '~': 'to review',
    },
  };

  String render(List<Pupil> pupils, {String locale = 'fr'}) {
    final buffer = StringBuffer()
      ..writeln(className)
      ..writeln();
    final width = pupils.fold<int>(6, (w, p) => p.firstName.length > w ? p.firstName.length : w);
    buffer.writeln('${' '.padRight(width)}  ${conceptIds.map((c) => c.padRight(6)).join()}');
    for (final pupil in pupils) {
      final line = StringBuffer(pupil.firstName.padRight(width))..write('  ');
      for (final conceptId in conceptIds) {
        final cell = rows.firstWhere(
          (r) => r.pupilId == pupil.id && r.conceptId == conceptId,
          orElse: () => GridCell(pupil.id, conceptId, ConceptState.nonVu, 0),
        );
        line.write(glyphs[cell.state]!.padRight(6));
      }
      buffer.writeln(line);
    }
    buffer
      ..writeln()
      ..writeln(legend[locale]!.entries.map((e) => '${e.key} ${e.value}').join('   '));
    return buffer.toString();
  }
}

/// Projection mode (`FR-M12-05`): one pupil's program, big and high-contrast, for the
/// whole class to discuss.
class ProjectionSettings {
  const ProjectionSettings({this.fontSize = 32, this.highContrast = true});
  final double fontSize;
  final bool highContrast;

  /// A projector in a lit classroom loses most of its contrast. 32 pt is the floor at
  /// which the back row can read a line of code from six metres.
  static const minimumFontSize = 28.0;

  bool get isLegibleFromTheBackRow => fontSize >= minimumFontSize && highContrast;
}
