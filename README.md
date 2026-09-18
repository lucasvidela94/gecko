# Gecko

Deletion as an output. Portable — POSIX `sh` + `git`, zero dependencies.

Ponytail prevents at write time. Gecko collects at close time: before a change
counts as done, every added line is either justified in writing or removed.

See [SPEC.md](SPEC.md) for the design and [SKILL.md](SKILL.md) for the agent
discipline.

## Install

Two files matter: the `gecko` script (mechanism) and `SKILL.md` (policy).

### 1. The script

Put `gecko` on your `PATH`, or copy it into the repo as `scripts/gecko`:

```sh
install -m 755 gecko ~/.local/bin/gecko
```

### 2. The skill

Copy `SKILL.md` into whatever harness you use — no edits needed, that is the
portability test:

```sh
mkdir -p ~/.config/opencode/skills/gecko && cp SKILL.md ~/.config/opencode/skills/gecko/
mkdir -p ~/.claude/skills/gecko         && cp SKILL.md ~/.claude/skills/gecko/
mkdir -p ~/.codex/skills/gecko          && cp SKILL.md ~/.codex/skills/gecko/
```

For harnesses without a skills directory, paste the body of `SKILL.md` into
`AGENTS.md`, `CLAUDE.md`, or the equivalent rules file.

## Use

```sh
gecko review                 # what did I add? rank reap targets
gecko review --base main     # same, over a branch
gecko check                  # ratchet: fail on new findings
gecko baseline --update      # freeze current findings as the baseline
gecko hook install           # hard enforcement at commit time
```

`review` is the reap pass. It flags **candidates** — files with additions and
zero deletions — ranked by size, and prints the changeset ratio:

```
gecko review (base: HEAD)

CANDIDATES (added, nothing removed)
  src/foo.ts                                   +142   -0
  src/bar.ts                                   +18    -0

summary: +252 -52  ratio 4.8:1  (candidates: 2)
```

`check` is the ratchet. Pre-existing debt is frozen; only new findings fail.

## Detectors

`gecko check` is language-agnostic. It runs whatever `.gecko/config` tells it
to. Define `gecko_detect()` to print one finding per line as
`<path><TAB><finding>`:

```sh
# .gecko/config — TypeScript/JavaScript
gecko_detect() {
  npx --yes knip --reporter compact 2>/dev/null | sed -E 's/^([^:]+):.*/\1\tknip/'
}
```

Without a config, the default detector is the **annotation ratchet**: it counts
unresolved `ponytail:` / `gecko:` markers. Zero setup, any language.

Known detectors you can plug in: `knip` (TS/JS), `vulture` (Python), `deadcode`
(Go), `cargo udeps` (Rust). Gecko does not install or know them; it only
compares the list before and after.

## Hard enforcement

`gecko hook install` writes a `pre-commit` hook that runs `gecko check`. For
CI, add the same command as a step — it exits non-zero on new findings.

## Layout

```
gecko/
├── SPEC.md        design (Spanish)
├── SKILL.md       agent discipline (English, portable)
├── gecko         the script
├── README.md      this file
└── examples/.gecko/config
```
