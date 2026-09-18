/// The Studio's project model (M9).
///
/// *"You are building the room where the child stops being a student and becomes an
/// author."* A project is what an author owns: sprites, backdrops, sounds, custom blocks,
/// lists, a name and a thumbnail. It is the only thing in KODO a child made rather than
/// completed, which is why the two rules that matter most here are that it is never lost
/// (autosave, ten versions) and that it round-trips exactly (export and reimport).
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Where an asset came from.
///
/// This is not bookkeeping. `FR-M10-01`'s adversarial review asks whether personal data
/// can be surfaced through an asset, and the answer depends entirely on this field: a
/// figure the child drew cannot contain a photograph of them, and one imported from the
/// device gallery can. [AssetOrigin.imported] is what the share gate refuses.
enum AssetOrigin {
  /// Drawn in KODO, on the canvas, by the child.
  drawn,

  /// Taken from KODO's own shipped library.
  library_,

  /// Brought in from the device's gallery or microphone, under `Capability.imageImport`
  /// or `Capability.microphone`.
  imported,
}

enum AssetKind { costume, backdrop, sound }

/// One asset. Content-addressed: the key is a hash, never a path and never a URL, so a
/// project file has nothing in it that has to resolve at run time.
class Asset {
  const Asset({
    required this.id,
    required this.kind,
    required this.name,
    required this.contentKey,
    required this.origin,
    required this.bytes,
  });

  final String id;
  final AssetKind kind;

  /// The child's name for it. Child-authored text, so it is moderated before it is
  /// shared — see `PersonalDataScan`.
  final String name;

  final String contentKey;
  final AssetOrigin origin;
  final int bytes;

  Map<String, Object?> toJson() => {
        'id': id,
        'kind': kind.name,
        'name': name,
        'key': contentKey,
        'origin': origin.name,
        'bytes': bytes,
      };

  static Asset fromJson(Map<String, Object?> j) => Asset(
        id: j['id']! as String,
        kind: AssetKind.values.byName(j['kind']! as String),
        name: j['name']! as String,
        contentKey: j['key']! as String,
        origin: AssetOrigin.values.byName(j['origin']! as String),
        bytes: (j['bytes'] as int?) ?? 0,
      );
}

/// A sprite in a project: a name, its costumes, and the program it runs (`FR-M9-02`).
///
/// Named `ProjectSprite` because M4 already owns `Sprite` — the thing on the stage that
/// has a position and a heading. This is the authored definition that one is built from.
class ProjectSprite {
  const ProjectSprite({
    required this.id,
    required this.name,
    required this.costumeIds,
    required this.source,
  });

  final String id;
  final String name;
  final List<String> costumeIds;

  /// Kept as **text**, not as a tree.
  ///
  /// The same reason `EditorController` keeps the child's text verbatim (defect `M3-001`):
  /// a project that re-renders itself from a parsed tree loses whatever did not parse, and
  /// in the Studio a child is allowed to save something half-written. Text is what they
  /// typed; the tree is derived when it runs.
  final String source;

  Map<String, Object?> toJson() =>
      {'id': id, 'name': name, 'costumes': costumeIds, 'source': source};

  static ProjectSprite fromJson(Map<String, Object?> j) => ProjectSprite(
        id: j['id']! as String,
        name: j['name']! as String,
        costumeIds: ((j['costumes'] as List<Object?>?) ?? const []).cast<String>(),
        source: (j['source'] as String?) ?? '',
      );
}

/// A named list (`FR-M9-02`).
class ProjectList {
  const ProjectList({required this.name, required this.values});
  final String name;
  final List<String> values;

  Map<String, Object?> toJson() => {'name': name, 'values': values};

  static ProjectList fromJson(Map<String, Object?> j) => ProjectList(
        name: j['name']! as String,
        values: ((j['values'] as List<Object?>?) ?? const []).cast<String>(),
      );
}

/// A custom block the child defined (`FR-M9-02`).
class CustomBlock {
  const CustomBlock({
    required this.name,
    required this.parameterNames,
    required this.source,
  });
  final String name;
  final List<String> parameterNames;
  final String source;

  Map<String, Object?> toJson() =>
      {'name': name, 'params': parameterNames, 'source': source};

  static CustomBlock fromJson(Map<String, Object?> j) => CustomBlock(
        name: j['name']! as String,
        parameterNames: ((j['params'] as List<Object?>?) ?? const []).cast<String>(),
        source: (j['source'] as String?) ?? '',
      );
}

/// Where a project came from (`FR-M9-01`).
enum ProjectOrigin { blank, template, remix }

/// Credit carried by a remix (`FR-M10-05`: *"remix is one tap and always attributes"*).
///
/// Note what is **not** here: no account id, no profile id, no device id. A remix names a
/// display name and a project, because the M10 interface rule is *"never exposes a child's
/// account identifiers to another child"*, and a field that does not exist cannot leak.
class RemixCredit {
  const RemixCredit({
    required this.originalProjectId,
    required this.originalAuthorDisplayName,
    required this.depth,
  });

  final String originalProjectId;
  final String originalAuthorDisplayName;

  /// How many remixes deep. Kept so a gallery can show the whole chain rather than only
  /// the last hop, which is how attribution quietly disappears.
  final int depth;

  Map<String, Object?> toJson() => {
        'project': originalProjectId,
        'author': originalAuthorDisplayName,
        'depth': depth,
      };

  static RemixCredit fromJson(Map<String, Object?> j) => RemixCredit(
        originalProjectId: j['project']! as String,
        originalAuthorDisplayName: j['author']! as String,
        depth: (j['depth'] as int?) ?? 1,
      );
}

/// A Studio project.
class Project {
  const Project({
    required this.id,
    required this.name,
    required this.origin,
    required this.sprites,
    required this.assets,
    required this.createdAt,
    required this.savedAt,
    this.customBlocks = const [],
    this.lists = const [],
    this.instructions = '',
    this.thumbnailSvg,
    this.remixOf,
    this.version = 1,
  });

  final String id;

  /// The child's name for it. Never required to be unique, never required at all — an
  /// untitled project is still a project, and demanding a name before the first block is
  /// how a five-minute idea becomes a form to fill in.
  final String name;

  final ProjectOrigin origin;
  final List<ProjectSprite> sprites;
  final List<Asset> assets;
  final List<CustomBlock> customBlocks;
  final List<ProjectList> lists;

  /// *"Instructions"* of `FR-M10-02`: how to play it. Child-authored, so moderated.
  final String instructions;

  /// Rendered from the canvas, never imported. See [Thumbnail].
  final String? thumbnailSvg;

  final RemixCredit? remixOf;
  final DateTime createdAt;
  final DateTime savedAt;
  final int version;

  Project copyWith({
    String? name,
    List<ProjectSprite>? sprites,
    List<Asset>? assets,
    List<CustomBlock>? customBlocks,
    List<ProjectList>? lists,
    String? instructions,
    String? thumbnailSvg,
    DateTime? savedAt,
    int? version,
  }) =>
      Project(
        id: id,
        name: name ?? this.name,
        origin: origin,
        sprites: sprites ?? this.sprites,
        assets: assets ?? this.assets,
        customBlocks: customBlocks ?? this.customBlocks,
        lists: lists ?? this.lists,
        instructions: instructions ?? this.instructions,
        thumbnailSvg: thumbnailSvg ?? this.thumbnailSvg,
        remixOf: remixOf,
        createdAt: createdAt,
        savedAt: savedAt ?? this.savedAt,
        version: version ?? this.version,
      );

  /// Every asset the child brought in from outside KODO.
  List<Asset> get importedAssets =>
      [for (final a in assets) if (a.origin == AssetOrigin.imported) a];

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'origin': origin.name,
        'version': version,
        'sprites': [for (final s in sprites) s.toJson()],
        'assets': [for (final a in assets) a.toJson()],
        'customBlocks': [for (final b in customBlocks) b.toJson()],
        'lists': [for (final l in lists) l.toJson()],
        'instructions': instructions,
        if (thumbnailSvg != null) 'thumbnail': thumbnailSvg,
        if (remixOf != null) 'remixOf': remixOf!.toJson(),
        'createdAt': createdAt.toUtc().toIso8601String(),
        'savedAt': savedAt.toUtc().toIso8601String(),
      };

  static Project fromJson(Map<String, Object?> j) => Project(
        id: j['id']! as String,
        name: j['name']! as String,
        origin: ProjectOrigin.values.byName(j['origin']! as String),
        version: (j['version'] as int?) ?? 1,
        sprites: [
          for (final s in (j['sprites'] as List<Object?>?) ?? const [])
            ProjectSprite.fromJson(s! as Map<String, Object?>),
        ],
        assets: [
          for (final a in (j['assets'] as List<Object?>?) ?? const [])
            Asset.fromJson(a! as Map<String, Object?>),
        ],
        customBlocks: [
          for (final b in (j['customBlocks'] as List<Object?>?) ?? const [])
            CustomBlock.fromJson(b! as Map<String, Object?>),
        ],
        lists: [
          for (final l in (j['lists'] as List<Object?>?) ?? const [])
            ProjectList.fromJson(l! as Map<String, Object?>),
        ],
        instructions: (j['instructions'] as String?) ?? '',
        thumbnailSvg: j['thumbnail'] as String?,
        remixOf: j['remixOf'] == null
            ? null
            : RemixCredit.fromJson(j['remixOf']! as Map<String, Object?>),
        createdAt: DateTime.parse(j['createdAt']! as String),
        savedAt: DateTime.parse(j['savedAt']! as String),
      );
}

/// The project file format (`FR-M9-05`).
///
/// The acceptance test is *"an exported project reimports identically"*, so, as with the
/// M18 item bank, the format is defined by the round trip: keys sorted everywhere, so the
/// bytes never depend on the order a `Map` happened to be built in.
class ProjectFile {
  const ProjectFile(this.project);

  static const schema = 'kodo.project/1';

  final Project project;

  String encode() => const JsonEncoder.withIndent('  ')
      .convert(canonical({'schema': schema, 'project': project.toJson()}));

  String get checksum => sha256.convert(utf8.encode(encode())).toString();

  static ProjectFile decode(String text) {
    final document = jsonDecode(text) as Map<String, Object?>;
    if (document['schema'] != schema) {
      throw FormatException('unknown project schema "${document['schema']}"');
    }
    return ProjectFile(
        Project.fromJson(document['project']! as Map<String, Object?>));
  }
}

/// Recursively sorts map keys, so encoding is deterministic.
Object? canonical(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((k) => k as String).toList()..sort();
    return {for (final key in keys) key: canonical(value[key])};
  }
  if (value is List) return [for (final entry in value) canonical(entry)];
  return value;
}
