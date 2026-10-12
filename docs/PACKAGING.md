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
| python | the tone hook | (program python3) |
| libpulse or pipewire | the chime (paplay or pw-play; it tries five players) | (programs) |

## The AUR recipe

Matches the AUR recipe 0.1.7-1. Nothing to change.
