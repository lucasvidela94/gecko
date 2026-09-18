# Contributing

Thanks for helping gecko.

## The one rule

gecko is intentionally tiny: **POSIX `sh` + `git`, no dependencies**. Keep it that
way. If a change needs a dependency or a language runtime, it probably belongs in
a *detector* (`.gecko/config`), not in the CLI.

## Run the checks

```sh
sh -n skills/gecko/scripts/gecko
sh -n install.sh
shellcheck -s sh skills/gecko/scripts/gecko install.sh
sh tests/smoke.sh
```

CI runs exactly these. All four must pass.

## Pull requests

- One concern per PR.
- Add a case to `tests/smoke.sh` for any behavior change.
- Update `CHANGELOG.md` under `## [Unreleased]`.
- Keep the diff small. Gecko is a tool about deleting code; a bloated PR here is
  a bad look.

## Reporting bugs

Use the issue templates. Include your `gecko version`, your OS, and how you
installed it.

## Scope

In scope: `review` / `check` / `baseline` / `hook`, the skill, the installer, the
ratchet semantics.

Out of scope: language-specific analysis (that is a detector), harness plugins,
and anything that adds a runtime dependency.

## License

By contributing you agree your work is released under the [MIT License](LICENSE).
