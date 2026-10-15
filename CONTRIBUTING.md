# Contributing

Thanks for your interest in improving `afromessage_dart`.

## Owner & maintainer

- **Miftah Fentaw** — [@Miftah-Fentaw](https://github.com/Miftah-Fentaw)

## How to contribute

1. Fork the repository and create a branch from `main`.
2. Make your changes with clear, focused commits.
3. Run checks locally:

```bash
dart pub get
dart analyze
dart test
dart format .
```

4. Open a pull request describing what changed and why.

## Guidelines

- Keep the public API stable unless a breaking change is intentional and called out in the PR / `CHANGELOG.md`.
- Prefer small, reviewable PRs.
- Add or update tests when you change behavior.
- Do not commit API tokens, secrets, or personal credentials.
- Match existing code style (`dart format`, package lints).

## Reporting issues

Use [GitHub Issues](https://github.com/Miftah-Fentaw/afromessage-dart/issues) for bugs and feature requests. Include:

- Package version
- Dart / Flutter version
- Minimal reproduction steps
- Expected vs actual behavior

## Releasing

1. Add a `## X.Y.Z` section to `CHANGELOG.md`.
2. From a clean `main` branch, run:

```bash
./scripts/release.sh X.Y.Z
```

That updates `pubspec.yaml`, runs checks, commits, tags `vX.Y.Z`, and pushes.
GitHub Actions then publishes to pub.dev when automated publishing is enabled.

## Questions

Open an issue or reach out via GitHub. For AfroMessage API behavior itself, see the [official docs](https://afromessage.com/developers).
