# Changelog

Versions are MAJOR.MINOR.PATCH. Major: breaks Sounds or the MIDI controller
numbers. Minor: features. Patch: fixes. The version is shown in the patcher
and on the second line of the XT's display as it starts up.

## Unreleased

## 1.1.0 — 2026-10-28

### New

- FX Para 1, FX Para 2 and FX Para 3: modulation destinations that move
  the three settings of a Sound's effect, such as a Chorus's Speed, a
  Delay's Feedback or an effect's Mix. Overdrive's Amp Type ignores FX
  Para 3. The note played last sets them. On release 1.0.0, a Sound that
  uses them moves the warp amounts of other voices instead, which is heard
  only when those voices' Sounds have a warp on.
- The FX Sounds: 16 bass Sounds that play their effect from velocity, key,
  clock LFOs, pressure and the wheel, four of them arpeggios. The
  Tallent Edition Sounds now fill B049 to B128.

### Changed

- MPE: Y is CC 74 alone, as the MPE specification sets it. The [MPE] page
  no longer chooses a second controller for Y.

### Fixed

- Microwave II: the effects no longer freeze the sound or distort the
  warps. A Microwave II (Board #1 on the Version page) plays 8 voices and
  has no X-Mod or Warp; their pages are hidden, and their MIDI controllers
  do nothing. Thanks to @nickb808-dev for reporting it (#1) and testing
  the fixes on a Microwave II.
- Microwave II: the modulation destination menu leaves out W1 Warp and W2
  Warp.
- The modulation Destination dial reaches every destination after a Multi
  has been loaded.
- Multi mode: the Multi keeps its name and part settings while notes play.
- MPE: when Manager pressure, Y or bend pushes a note to its limit and then
  returns, the note goes back to its own Member value instead of below it.

## 1.0.0 — 2026-10-26

### New

- Oscillator 2's wavetable: Osc2 can play a wavetable of its own.
- X-Mod: phase and amplitude modulation alongside FM, in either direction.
- Warp: nine ways to reshape each oscillator's wave, with W1 Warp and
  W2 Warp as modulation destinations.
- Honda Aliasing: two Aliasing settings that follow the Piston Honda Mk II.
- Interpolation: the wave position glides between waves, as on the E352
  and the Piston Honda, with Startwave Fine in hundredths of a wave.
- MPE input with per-note pitch bend, pressure and Y.
- MIDI controllers for every new setting.
- The Tallent Edition Sounds: 60 Sounds and nine wavetables.

### Changed

- An XT with the 30-voice expansion plays 25 voices.
- The demo song and the power-up front-panel test are removed.
