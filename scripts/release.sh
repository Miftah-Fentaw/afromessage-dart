#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: ./scripts/release.sh <version>"
  echo "Example: ./scripts/release.sh 1.0.1"
  exit 1
fi

VERSION="$1"

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.+][0-9A-Za-z.-]+)?$ ]]; then
  echo "Error: version must look like 1.2.3 (got: $VERSION)"
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [ -n "$(git status --porcelain)" ]; then
  echo "Error: working tree is dirty. Commit or stash changes first."
  exit 1
fi

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [ "$BRANCH" != "main" ]; then
  echo "Error: must be on main (currently on $BRANCH)"
  exit 1
fi

TAG="v$VERSION"
if git rev-parse "$TAG" >/dev/null 2>&1; then
  echo "Error: tag $TAG already exists"
  exit 1
fi

if ! grep -Eq "^##[[:space:]]+$VERSION([[:space:]]|\$)" CHANGELOG.md; then
  echo "Error: CHANGELOG.md has no '## $VERSION' heading."
  echo "Add a changelog section for $VERSION before releasing."
  exit 1
fi

if grep -Eq "^version:" pubspec.yaml; then
  sed -i.bak -E "s/^version:[[:space:]].*/version: $VERSION/" pubspec.yaml
  rm -f pubspec.yaml.bak
else
  echo "Error: could not find version: in pubspec.yaml"
  exit 1
fi

dart pub get
dart analyze --fatal-infos
dart test
dart pub publish --dry-run

git add pubspec.yaml
git commit -m "Release v$VERSION"
git tag "$TAG"
git push origin main --tags

echo "Released $TAG. Publish workflow should run on GitHub Actions."
