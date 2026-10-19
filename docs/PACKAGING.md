# mindForge — what the package needs

*Measured from the code on 2026-10-11 (the Forge Suite dependency audit), with the Forge Suite's audit, `forge-suite/scripts/needs-audit.py`, and proven by building the
AUR recipe in a clean Arch system (devtools' `makechrootpkg`, tests included). Kept current by running the audit at every release.
Arch's `base` packages (bash, coreutils, glibc, sed, grep, util-linux, systemd…) are on every Arch install and
aren't listed.*

## Needs (the recipe's `depends`)

| Package | What uses it | Module / program |
|---|---|---|
| bash | everything | — |
| git | the brief and wrap read the projects' history | (program) |
| coreutils, grep, sed, gawk | the recipe names these base tools explicitly (harmless) | — |

## Optional (`optdepends`)

| Package | What uses it | Module / program |
|---|---|---|
| github-cli | issues and the repo watch (gh) | (program gh) |
| libnotify | desktop messages | (program notify-send) |
| python | the tie alert, `mindforge tone` (it tries python3, python, `py -3`) | (program python3) |
| libpulse or pipewire | the chime (paplay or pw-play; it tries five players) | (programs) |

## Needed to run the tests (`checkdepends`)

| Package | Why |
|---|---|
| python | the recipe's `check()` runs `testing/run-tests.sh`, and its tie-alert checks need a python that runs (#64). Until 0.1.9 the recipe did not ask for it, and the clean-chroot build passed only because something else pulled python in |

## Windows only (not packaged)

| Program | What uses it |
|---|---|
| cygpath (Git for Windows) | the memory folder's name (#15) and the tie alert's transcript path (#65); absent elsewhere, and nothing needs it there |
| PowerShell 7 | `bin/mindforge.ps1`, the PowerShell wrapper (#21) |

## The AUR recipe

0.1.9-1: adds `checkdepends=('python')` (#64), and corrects `license` from GPL3 to **MIT**, which is what `LICENSE` and GitHub have always said (#66; the recipe was wrong since 0.1.7). The python optdepend now says what uses it: the tie alert.
