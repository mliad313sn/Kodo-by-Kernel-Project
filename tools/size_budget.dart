// The size budget, checked in CI (`NFR-SIZE-01`, `FR-M14-02`).
//
//     dart run tools/size_budget.dart
//
// Two numbers the specification fixes, and one it does not:
//
//   * **12 MB per world**, audio included. `FR-M14-02`. A world that does not fit has to
//     be split or cut, and finding that out at release time is finding it out too late.
//   * **180 MB for the whole curriculum.** `NFR-SIZE-01`. Thirteen worlds of JSON is not
//     the problem; thirteen worlds of recorded narration is, which is why the estimate
//     below counts audio rather than files on disk.
//   * **25 MB for the base app**, which this tool cannot measure: it needs a built
//     binary, a platform and a toolchain. It is reported as unmeasured rather than
//     guessed at — a budget check that quietly skips the number it cannot see is worse
//     than no check, because it reads as a pass.
//
// Audio is estimated at 40 KB per recording, which is one line of Opus narration at the
// bitrate `FR-M15-05` settled on. The estimate is deliberately in this file rather than
// hidden in a library: when the real recordings land, this is the number to correct.
library;

import 'dart:convert';
import 'dart:io';

/// One line of narration or one prompt, as Opus at the shipped bitrate.
const bytesPerRecording = 40 * 1024;

/// `FR-M14-02`.
const worldBudget = 12 * 1024 * 1024;

/// `NFR-SIZE-01`, the whole curriculum.
const curriculumBudget = 180 * 1024 * 1024;

String mb(int bytes) => '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';

void main() {
  final dir = Directory('content');
  if (!dir.existsSync()) {
    stderr.writeln('no content/ — run the authoring tools first');
    exit(1);
  }

  var total = 0;
  var failures = 0;
  // The report is written as well as printed, so CI can keep it as evidence beside the
  // traceability table rather than only in a log that scrolls away.
  final report = StringBuffer();
  void say(String line) {
    stdout.writeln(line);
    report.writeln(line);
  }

  say('World   JSON      audio     total     of 12 MB');
  for (var world = 0; world <= 12; world++) {
    final file = File('content/world$world.json');
    if (!file.existsSync()) continue;
    /* Read as plain JSON rather than through `ContentPack`, so this gate runs from the
       repository root with no package resolution — the same way the traceability gate
       does, and for the same reason: a check that needs a build to run is a check that
       stops running. */
    final pack = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
    final json = file.lengthSync();
    final keys = ((pack['audio'] as List<Object?>?) ?? const [])
        .cast<String>()
        .toSet();
    final audio = keys.length * bytesPerRecording;
    final size = json + audio;
    total += size;
    final share = size / worldBudget * 100;
    say('${world.toString().padLeft(5)}   '
        '${mb(json).padLeft(8)}  ${mb(audio).padLeft(8)}  '
        '${mb(size).padLeft(8)}  ${share.toStringAsFixed(1).padLeft(6)} %');
    if (size > worldBudget) {
      stderr.writeln('OVER BUDGET: world $world is ${mb(size)}, '
          'and FR-M14-02 allows ${mb(worldBudget)}');
      failures++;
    }
  }

  say('\ncurriculum: ${mb(total)} of ${mb(curriculumBudget)} '
      '(${(total / curriculumBudget * 100).toStringAsFixed(1)} %)');
  if (total > curriculumBudget) {
    stderr.writeln('OVER BUDGET: NFR-SIZE-01 allows ${mb(curriculumBudget)}');
    failures++;
  }

  /* The base app. Not measured, and said so. A binary needs a platform, a toolchain and
     a release build; this tool has none of the three, and a check that prints nothing
     about a number it cannot see reads as a pass. */
  say('base app:   not measured here — needs a release build. '
      'NFR-SIZE-01 allows ${mb(25 * 1024 * 1024)}.');

  Directory('build').createSync(recursive: true);
  File('build/size_budget.txt').writeAsStringSync(report.toString());

  if (failures > 0) exit(1);
  stdout.writeln('OK');
}
