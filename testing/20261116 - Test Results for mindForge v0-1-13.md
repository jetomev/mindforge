# Test Results for mindForge v0.1.13

*Run 2026-11-16 18:27–18:28 on the home PC, against the locally built AUR package 0.1.13-1
(`/usr/bin/mindforge`). Matrix: `20261116 - Test Matrix for mindForge v0-1-13.md`. A1 by the maintainer;
A2–A6 by `scripts/test-installed.sh` (log `logs/test-installed-20261116-182745.log`, kept locally); A7 by Claude.*

| # | Step | Result |
|---|---|---|
| A1 | `nog install ./mindforge-0.1.13-1-any.pkg.tar.zst` | ✅ 0.1.12-1 → 0.1.13-1, no errors |
| A2 | `--version` | ✅ `mindforge 0.1.13` |
| A3 | `rot` | ✅ the long-standing warnings end in `(N sessions -- fix it)` |
| A4 | `memcheck --shell` on an in-place `sed` of a memory note | ✅ refused, exit 1 |
| A5 | `memcheck --shell` on a read | ✅ nothing printed, exit 0 |
| A6 | `heard --check "I never asked for that"` | ✅ `I never asked` |
| A7 | `cmp` of `/usr/bin/mindforge` with `bin/mindforge` at the tag | ✅ identical: F-2's fix is what is installed |
| A8 | the desk chat opened 2026-11-16 18:09 keeps its start mark the next morning | — follow-up, does not hold the AUR |

## Verdict
A1–A7 pass, 0 failed. 0.1.13-1 is ready for the one AUR push. A8 is checked at the next morning's wrap.
