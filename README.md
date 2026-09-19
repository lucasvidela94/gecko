<div align="center">
  <img src="assets/gecko.png" width="180" alt="gecko">
  <h3>Deletion as an output.</h3>
  <p>A portable skill + zero-dependency CLI that makes removing orphaned code<br>
  a required step of every change.</p>
  <p><em>He says nothing. He deletes what's dead. It still works.</em></p>
  <p>
    <a href="https://github.com/lucasvidela94/gecko/releases"><img src="https://img.shields.io/github/v/release/lucasvidela94/gecko?color=8FAE8B&labelColor=1b1b1b" alt="release"></a>
    <a href="LICENSE"><img src="https://img.shields.io/github/license/lucasvidela94/gecko?color=8FAE8B&labelColor=1b1b1b" alt="license"></a>
    <a href="https://github.com/lucasvidela94/gecko/actions/workflows/ci.yml"><img src="https://github.com/lucasvidela94/gecko/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
    <a href="https://skills.sh/lucasvidela94/gecko"><img src="https://skills.sh/b/lucasvidela94/gecko" alt="skills.sh"></a>
    <a href="https://github.com/lucasvidela94/gecko/stargazers"><img src="https://img.shields.io/github/stars/lucasvidela94/gecko?color=8FAE8B&labelColor=1b1b1b" alt="stars"></a>
  </p>
</div>

Ponytail prevents at write time. **Gecko collects at close time.** Before a change
counts as done, every added line is either justified in writing, or removed.

Git is the memory — it survives compaction, restarts and harness changes. A
ratchet is the enforcement — it refuses to let the debt grow.

## Install

```bash
npx skills add lucasvidela94/gecko -g -y
```

That installs the skill — and its CLI — into every agent it finds: OpenCode,
Claude Code, Codex, Cursor and [75+ more](https://skills.sh). No other setup.

Want `gecko` on your `PATH` too, or no Node?

```bash
curl -fsSL https://raw.githubusercontent.com/lucasvidela94/gecko/main/install.sh | sh
```

Pin a version with `--version v0.2.0`, choose a bin dir with `--bin DIR`, skip a
half with `--no-cli` / `--no-skill`.

## Demo

```console
$ gecko review
gecko review (base: HEAD)

GREW (existed before, added lines, deleted none)
  src/report.js                                +5      -0

NEW FILES (all additions by definition)
  src/csv.js                                   +18     -0

summary: +23 -0  ratio n/a:1  (grew: 1, new: 1, tests hidden: 0, untracked: 0)

$ gecko check
NEW findings (nothing references these):

  src/csv.js    legacyExport kept for the old CLI — remove when the old CLI is gone

Wire it up, delete it, or update the baseline saying why in the commit.

$ # delete what's dead, then:
$ gecko check
no new findings

$ gecko review
NEW FILES (all additions by definition)
  src/csv.js                                   +9      -0     ← was +18
```

Nine dead lines gone, no live line touched. `gecko hook install` makes the last
step impossible to skip — the commit is blocked until `check` passes.

## Use

```bash
gecko review                 # what did I add? rank the reap targets
gecko review --base main     # same, over a branch
gecko review --json          # machine-readable
gecko check                  # ratchet: fail on new findings
gecko check --json           # machine-readable verdict (clean | findings)
gecko baseline               # show what would be frozen (writes nothing)
gecko baseline --update      # freeze current findings
gecko hook install           # hard enforcement at commit time
gecko self-update            # update the standalone CLI
```

`review` is the reap pass. **ORPHANS** come first: modules that lost their last
caller in this diff (a hook that replaced a service), plus one hop of their
private imports. Then **GREW** — files that already existed and only gained
lines — and **NEW FILES**, which are all additions by definition. Test files are
hidden unless `--tests`; long lists are capped unless `--all`.

`check` is the ratchet. Pre-existing debt is frozen in `.gecko/baseline` and left
alone; only **new** findings fail.

## Detectors

`gecko check` is language-agnostic. It runs whatever a **committed**
`.gecko/config` tells it to. An untracked config is ignored. Define
`gecko_detect()` to print one finding per line as `<path><TAB><finding>`:

```sh
# .gecko/config — TypeScript/JavaScript
# knip's compact reporter prints "<path>: <symbol>[, <symbol>]".
gecko_detect() {
  npx --yes knip --no-progress --reporter compact 2>/dev/null \
    | awk -F': ' 'NF >= 2 { n = split($2, a, ", "); for (i = 1; i <= n; i++) print $1 "\t" a[i] }'
}
```

Without a config, the default detector is the **annotation ratchet**: it counts
unresolved comment-shaped `ponytail:` / `gecko:` markers (`#` / `//` / `--`).
It skips `docs/`, `vendor/`, markdown and editor/agent trees. Zero setup, any
language — but it only sees annotations, so `check` says so on stderr and points
you here. Set `GECKO_QUIET=1` to silence that notice in CI. If the detector
exits non-zero, `check` fails closed (`detector_failed`); it will not look clean.

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

## How it works

- **Git is the memory.** No session ledger to lose. `blame`, `log` and `diff`
  survive compaction, restarts and switching agents.
- **Ratchet, not gate.** Demanding zero dead code means the guard never turns on,
  because the pre-existing debt blocks it. Gecko freezes what exists and refuses
  growth — the part that pays for itself.
- **Two layers.** The skill convinces inside the session; the pre-commit hook and
  CI enforce regardless of what the model decided.
- **Portable.** The same `SKILL.md` works unchanged across every agent. That is
  the point, and the test.

## Built for agents first

The primary user is an LLM, not a human. It cannot ask questions, it does not see
a spinner, it pays per token, and it is literal. So:

- **Non-interactive and safe to re-run.** Nothing is innocently destructive:
  `baseline` writes nothing without `--update`.
- **Every failure carries the fix.** Success is exactly `no new findings`; a new
  finding states the three ways out. A dead detector prints `detector_failed`
  and refuses to write a baseline.
- **Parseable verdicts.** `--json` on `review` and `check` gives a stable shape.
- **Cheap.** Output is capped by default (`--all` lifts it), and `--json` mirrors
  the caps with a `truncated` flag, so nothing is dropped silently.
- **The skill and the CLI speak one vocabulary.** The sections the skill tells
  the agent to look for are the sections the CLI prints.

That last rule is the whole idea: a flow that is comfortable for a developer must
be *obvious* for an agent.

## Works with

OpenCode · Claude Code · Codex · Cursor · GitHub Copilot · Windsurf · Cline ·
Gemini CLI · Kiro · Zed · AMP · Goose · and [75+ more](https://skills.sh) —
one command, no per-agent setup.

## What it does not do

Gecko finds orphaned additions, leftover modules after a replacement, and
annotation debt. It does **not** find a dead branch inside a live function, a
field nothing assigns, or a function that is called but whose effect is dead.
Those are found by running the product, not by reading a diff. It does not
analyze your language; plug in a detector for that. ORPHANS is an import
heuristic, not a call graph.

## Update

Installed with `npx skills`? The skills CLI owns both the skill and its CLI:

```bash
npx skills update
```

CLI on your `PATH`? Then:

```bash
gecko self-update          # fetch the latest release
gecko self-update --check  # just report, change nothing
```

## Security

- POSIX `sh` + `git`. No network, no telemetry, no dependencies.
- It writes only under your repo's `.gecko/`, and — on `hook install` — one
  `pre-commit` hook. Nothing else.
- `.gecko/config` is sourced as shell, and only once it is tracked. Commit it
  on purpose; an untracked copy is ignored.
- `self-update` is the only command that touches the network, and it fetches
  from this repository's GitHub releases.

## Contributing

Small diffs, POSIX `sh`, no dependencies. See [CONTRIBUTING.md](CONTRIBUTING.md).
Run `sh tests/smoke.sh` — CI runs the same.

## License

MIT. See [LICENSE](LICENSE).

---

<sub>If gecko deleted a few lines you were going to keep, a ⭐ helps others find it. Pairs with <a href="https://github.com/DietrichGebert/ponytail">ponytail</a>.</sub>
