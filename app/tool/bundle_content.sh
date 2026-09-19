#!/bin/sh
# Copies the authored worlds into the app's asset bundle.
#
# Flutter will not take an asset from outside the package directory, and `content/` at the
# repository root is the canonical location every test and author tool uses. So the app
# carries a COPY, and `test/m19_acceptance_test.dart` fails if the copy drifts — a stale
# bundled world would ship a child content that no longer matches the bank CI checked.
#
#     sh tool/bundle_content.sh
set -e
cd "$(dirname "$0")/.."
mkdir -p assets/content
cp ../content/world*.json assets/content/
echo "bundled: $(ls assets/content | tr '\n' ' ')"
