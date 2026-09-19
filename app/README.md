# kodo

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

---

# KODO — the application (M19)

This is the body the eighteen modules go inside. Until PO decision `D-012` it did not
exist: eighteen modules were built, all eighteen passed their acceptance tests, and none of
them was the application.

```bash
sh tool/bundle_content.sh     # copy the authored worlds into the asset bundle
flutter pub get
flutter test                  # 20 acceptance tests, FR-M19-01 … 06
flutter run                   # android · linux · web

# or build the web target, which needs no CDN — FR-M14-01 forbids a network call
flutter build web --release --no-web-resources-cdn
```

## What it owns, and what it must never own

It composes modules: the block editor is M2, the canvas is M4, grading is M6, progression
is M7, the content is M14, the strings are M15, the preferences are M16. It holds **no
grader, no mastery rule, no scheduler and no item** — `FR-M19-06`, enforced by a dependency
test rather than by a convention, because a convention would not survive the second sprint.

## What is owed

| Item | Note |
| --- | --- |
| iOS, macOS and Windows targets | `flutter create` was run for android, linux and web |
| Web session persistence | The browser build does not remember a child's place; see `lib/src/platform_web.dart` |
| Cold start measured on the reference device | `FR-M19-05` is proven logically and not yet on glass |
| The tutorial player, gallery, parent space and classroom screens | Squad S2, per the delivery charter |
