---
name: gecko
description: >
  Reap leftover code at close time. Before a coding change is done, every
  added line is justified or deleted, and ORPHANS — modules that lost their
  last caller, like a service a new hook replaced — are removed. Use when
  finishing a change, replacing a module, the user says reap, or the session
  has only been adding code.
argument-hint: "[lite|full|ultra]"
license: MIT
---

# Gecko

A change is not closed until it has been **reaped**: every added line justified
or deleted, and every **ORPHAN** gone.

Commands are `gecko`. If it is not on `PATH`, run `scripts/gecko` next to this
skill. Default intensity is **full** (`lite` reports; `ultra` walks another hop
after each delete).

<what-to-do>

1. Run `gecko review`. Done when its output is on screen. If it printed
   **ORPHANS**, this change replaced a path — step 2. Otherwise step 3.
2. **Replacement.** Delete each ORPHANS path, hop 0 then hop 1. The NEW FILE
   is the replacement. Run `gecko review` again. Done when ORPHANS is absent,
   or every remaining path still has a caller you can name. Then step 3.
3. **Accretion.** For each GREW file, each added block: keep it only if its
   reason still exists. Skim TOUCHED with a large `+` and a tiny `-`. Done when
   every surviving addition has a reason.
4. A shortcut that stays gets `# gecko: <reason> — remove when <condition>`,
   and only when both halves are true.
5. Run `gecko check`. Done when stdout is exactly `no new findings`.
   `detector_failed` means fix the detector, not the baseline. Any other
   output means wire it, delete it, or explain it — pick one.

</what-to-do>

<supporting-info>

## Ratchet

`gecko check` refuses **growth**, not existence. Pre-existing debt stays in
`.gecko/baseline`. Tightening the baseline is its own commit with a reason
(`gecko baseline --update`).

## Sections

The CLI names the work. Look for exactly these: **ORPHANS**, **GREW**,
**NEW FILES**, **TOUCHED**, `no new findings`.

ORPHANS are modules that lost their last caller in this diff, plus one hop of
imports that existed only for them. That is the leftover service after a hook
lands. It follows dropped `import` / `from` / `require`, not a call graph.

## Intensity

| Level | Demand |
|-------|--------|
| **lite** | Run the reap; report ORPHANS and GREW; delete only when asked. |
| **full** | Delete ORPHANS and unjustified additions. `gecko check` clean. |
| **ultra** | Another hop after each delete. Name why every surviving addition stays. |

## Outside this pass

A dead branch inside a live function, a field nothing assigns, an effect that
is called but does nothing — those need the product running, not this diff.

`stop gecko` / `normal mode` ends the pass for the session. Level holds until
changed or session end.

</supporting-info>
