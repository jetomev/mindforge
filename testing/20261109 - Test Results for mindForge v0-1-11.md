# Test Results for mindForge v0.1.11

*Run 2026-11-09 by the maintainer on the home PC, against the locally built AUR package 0.1.11-1
(`/usr/bin/mindforge`). Matrix: `20261109 - Test Matrix for mindForge v0-1-11.md`. A2–A6 were run by
`scripts/test-installed.sh`, which logs what each step printed.*

| # | Step | Result |
|---|---|---|
| A1 | `nog install ./mindforge-0.1.11-1-any.pkg.tar.zst` | ✅ 0.1.10-1 → 0.1.11-1, one package; pacman showed the new python optdepend line |
| A2 | `--version` | ✅ `mindforge 0.1.11` |
| A3 | `rot` | ✅ six long-standing warnings end in `(N sessions -- fix it)`; R7 also named a real stale index line (fixed the same minute) |
| A4 | `memcheck --shell` on an in-place `sed` of a memory note | ✅ refused, exit 1, "sed -i on a memory file" |
| A5 | `memcheck --shell` on a read of the same note | ✅ nothing printed, exit 0 |
| A6 | `heard --check "I never asked for that"` | ✅ `I never asked` |
| A7 | a new session the maintainer opened and typed into: quote any note in front of the message | ✅ the turn note arrived word for word · ❌ **F-1**, below |

## F-1 · Another session's style slip reached a brand-new session

The new session quoted, after the turn note: *"Your last reply was caught with: a bold line used as a
heading. Do not repeat it."* It had sent no reply yet. It pointed it out itself: the catch must have
carried over from an earlier session.

Cause: `mindforge tone` wrote every slip to one shared file, `tone.pending`, and `heard` handed it to
whichever session spoke next. The slip was real, but it was the release session's, not the new one's.

Fix (0.1.12): one file per session (`tone.pending.<session>`). `heard` reads only its own session's file;
it clears the shared file of 0.1.11 unread, and any session's file older than two days. 6 checks, the
shared-file case seen failing on the 0.1.11 build. The fix goes out as 0.1.12; 0.1.11-1 never reaches
the AUR, and the one AUR push is 0.1.12-1 after its own retest.

## Verdict

A1–A6 pass; A7 passes on what it was written for (the turn note arrives in a typed session) and found F-1.
The proof the brain's part 1 still lacked, the style note arriving in a session the maintainer typed into,
is done.
