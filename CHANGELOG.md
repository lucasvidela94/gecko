# Changelog

All notable changes to this project are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning: [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.2.0] - 2026-09-18

### Added

- `gecko self-update` for the standalone CLI: resolves the latest release,
  atomic replace, refuses to downgrade, refuses to touch a skill-managed copy.
- `gecko self-update --check`.
- Mascot and README header.

### Changed

- Repo layout follows the skills ecosystem: `skills/gecko/SKILL.md` +
  `skills/gecko/scripts/gecko`.

## [0.1.0] - 2026-09-18

### Added

- `gecko review`, `gecko check`, `gecko baseline`, `gecko hook install|uninstall`.
- Annotation ratchet detector (`ponytail:` / `gecko:`) and pluggable detectors
  via `.gecko/config`.
- Skill + CLI. POSIX `sh` + `git`, zero dependencies.
- `install.sh` and distribution through [skills.sh](https://skills.sh/lucasvidela94/gecko).

[Unreleased]: https://github.com/lucasvidela94/gecko/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/lucasvidela94/gecko/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/lucasvidela94/gecko/releases/tag/v0.1.0
