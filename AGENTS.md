# Microwave XT contributor notes

This repository builds an unofficial firmware extension for the Waldorf
Microwave II, XT and XTk, operating system 2.33. `src/hooks.asm` replaces
listed byte ranges of the stock image; `src/features/` is the code
assembled after it. `src/stock_abi.inc` holds the stock addresses the code
assembles against and `src/patch_layout.json` the ranges the patch
replaces. `tools/make_patch.py` builds the patch, and `web/` applies it to a
user's own copy of Waldorf's update. Never add Waldorf software, a patched
update file, or a disassembly to the repository.

`src/hooks.asm`, `src/stock_abi.inc`, `src/patch_layout.json` and
`src/features/xmod/dsp_stream*.inc` are generated from the full source of
the edition, which is not published. Change them there.

Documentation contains current facts and contracts. History lives in Git.

## Workflow

Carry implementation requests through edits and relevant verification.
Resolve routine choices from the task and current code; ask only when a
missing decision materially affects the result. Read-only reviews and
diagnoses end with findings unless implementation is requested.

Validate external data at its entry point and trust internal callers. Keep
the stock update hash, the hunk and extension bounds, and the result hashes
intact. A patch may only replace the listed byte ranges and fill the
extension region after the stock image. Delete dead code with its build
entries. Do not add durable tests for new work; use existing checks and
focused temporary experiments.

Sound bytes and MIDI controller numbers are contracts other people's
editors depend on. Change them only by adding, and update the New Features
Guide in the same commit.

A change users will notice adds a line under `## Unreleased` in
`CHANGELOG.md`, in plain words, in the same commit; note what an earlier
release makes of Sounds it saves. `VERSION` changes only with a release.

For code changes, run `make check`; with Waldorf's OS v2.33 update at hand,
`XT_STOCK_UPDATE=/path/to/mw2_xt_xtk_sys_v233.mid make check` also applies
the patch with the browser patcher under Node. Run `make release` when
patch generation or packaging changes. Documentation or agent configuration
changes require only diff and syntax review. Nothing here proves a build on
hardware: say what was and was not run on an XT.

After completing requested changes and verification, commit them unless the
user asks to leave them uncommitted. Stage only the task's changes. Pushing
requires separate user direction. Report the result, verification, and
remaining limits in concise prose.
