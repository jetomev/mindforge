# Test Results for mindForge v0.1.12

*Run 2026-11-09 21:52–21:55 by the maintainer on the home PC, against the locally built AUR package
0.1.12-1 (`/usr/bin/mindforge`). Matrix: `20261109 - Test Matrix for mindForge v0-1-12.md`. A2–A6 by
`scripts/test-installed.sh` (log `logs/test-installed-20261109-215250.log`, kept locally).*

| # | Step | Result |
|---|---|---|
| A1 | `nog install ./mindforge-0.1.12-1-any.pkg.tar.zst` | ✅ 0.1.11-1 → 0.1.12-1, no errors |
| A2 | `--version` | ✅ `mindforge 0.1.12` |
| A3 | `rot` | ✅ the long-standing warnings end in `(N sessions -- fix it)` |
| A4 | `memcheck --shell` on an in-place `sed` of a memory note | ✅ refused, exit 1 |
| A5 | `memcheck --shell` on a read of the same note | ✅ nothing printed, exit 0 |
| A6 | `heard --check "I never asked for that"` | ✅ `I never asked` |
| A7 | a new session the maintainer opened and typed into: quote any note in front of the message | ✅ the turn note word for word, and no "Your last reply was caught with" line: F-1 (#75) fixed |

## Verdict

All pass. AUR 0.1.12-1 pushed (`adaccbf`) the same evening, the one push for 0.1.11 and 0.1.12;
the AUR page shows 0.1.12-1 and its recipe is identical to the one tested. #75 closed with this result.
