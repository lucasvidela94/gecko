# Changelog

All notable changes to this project are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning: [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.6.0] - 2026-09-18

### Added

- `check` and `baseline` warn on stderr when no detector is configured, naming
  the annotation ratchet and how to add a real one. `GECKO_QUIET=1` silences it.
  A first-time user (often an agent) no longer sees `no new findings` and
  concludes the tool does nothing.

## [0.5.0] - 2026-09-18

### Changed

- `gecko review --json` now mirrors the human caps: GREW is complete, NEW FILES
  and TOUCHED are capped unless `--all`. A `"truncated"` flag states plainly when
  rows were omitted, so nothing is dropped silently. On a real 138-commit branch
  this cut the default JSON payload from ~15 KB to ~4 KB.

## [0.4.0] - 2026-09-18

### Added

- `gecko check --json` — machine-readable verdict:
  `{"verdict":"clean"|"findings","new_count":N,"findings":[...]}`.
- Agent-DX pass: the skill now names the exact sections the CLI prints
  (`GREW`, `NEW FILES`, `no new findings`). The skill and the CLI are one
  contract.

### Changed

- `gecko baseline` no longer writes by default; it shows what would be frozen.
  `gecko baseline --update` writes. This matches what the docs already said and
  removes a footgun for agents that run commands without hesitation.

## [0.3.0] - 2026-09-18

### Changed

- `gecko review` now separates **GREW** (existing files that only gained lines —
  where dead code hides) from **NEW FILES** (all additions by definition), and
  puts GREW first. On a real 138-commit branch this took the output from 85
  undifferentiated candidates to 18 actionable ones.
- Test files are hidden unless `--tests`; the long secondary lists are capped
  unless `--all`.
- The summary now reports grew / new / tests hidden.

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

[Unreleased]: https://github.com/lucasvidela94/gecko/compare/v0.6.0...HEAD
[0.6.0]: https://github.com/lucasvidela94/gecko/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/lucasvidela94/gecko/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/lucasvidela94/gecko/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/lucasvidela94/gecko/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/lucasvidela94/gecko/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/lucasvidela94/gecko/releases/tag/v0.1.0
