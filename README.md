# gecko

**Deletion as an output.** A portable skill + zero-dependency CLI that makes
removing orphaned code a required step of every change.

Ponytail prevents at write time. Gecko collects at close time: before a change
counts as done, every added line is either justified in writing or removed.

Git is the memory (it survives compaction, restarts and harness changes). A
ratchet is the enforcement (it refuses to let the debt grow).

[![skills.sh](https://skills.sh/b/lucasvidela94/gecko)](https://skills.sh/lucasvidela94/gecko)

## Install

```bash
npx skills add lucasvidela94/gecko -g -y
```

That installs the skill — and its CLI — into every agent it finds: OpenCode,
Claude Code, Codex, Cursor and 75 more. No other setup.

Want `gecko` on your `PATH` too, or no Node? Either works, or both:

```bash
curl -fsSL https://raw.githubusercontent.com/lucasvidela94/gecko/main/install.sh | sh
```

Pin a version with `--version v0.1.0`, choose a bin dir with `--bin DIR`, skip a
half with `--no-cli` / `--no-skill`.

## Use

```bash
gecko review                 # what did I add? rank the reap targets
gecko review --base main     # same, over a branch
gecko review --json          # machine-readable
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

`check` is the ratchet. Pre-existing debt is frozen in `.gecko/baseline` and left
alone; only **new** findings fail. It refuses growth, not existence — a gate that
demands zero never activates, because the pre-existing debt blocks it.

`hook install` writes a `pre-commit` that runs `check`. The agent can ignore the
skill; git cannot ignore the hook.

## Detectors

`gecko check` is language-agnostic. It runs whatever `.gecko/config` tells it to.
Define `gecko_detect()` to print one finding per line as `<path><TAB><finding>`:

```sh
# .gecko/config — TypeScript/JavaScript
gecko_detect() {
  npx --yes knip --reporter compact 2>/dev/null | sed -E 's/^([^:]+):.*/\1\tknip/'
}
```

Without a config, the default detector is the **annotation ratchet**: it counts
unresolved `ponytail:` / `gecko:` markers. Zero setup, any language.

Detectors you can plug in: `knip` (TS/JS), `vulture` (Python), `deadcode` (Go),
`cargo udeps` (Rust). Gecko does not install or know them; it only compares the
list before and after.

## The annotation convention

When an addition stays on purpose, say why, in the code:

```js
// gecko: retry loop until the API paginates — remove when it does
```

False annotations are worse than dead code, because they look handled. Gecko's
ratchet counts them, so the excuse has to be honest.

## What it does not do

Gecko finds orphaned additions and annotation debt. It does **not** find a dead
branch inside a live function, a field nothing assigns, or a function that is
called but whose effect is dead. Those are found by running the product, not by
reading a diff. It does not analyze your language; plug in a detector for that.

## Security

- POSIX `sh` + `git`. No network, no telemetry, no dependencies.
- It writes only under your repo's `.gecko/`, and — on `hook install` — one
  `pre-commit` hook. Nothing else.

## Layout

```
gecko/
├── skills/gecko/SKILL.md        the discipline (what the agent reads)
├── skills/gecko/scripts/gecko   the CLI (what the agent runs)
├── install.sh                   curl installer
├── examples/.gecko/config       detector examples
└── SPEC.md                      the design
```

## License

MIT.
