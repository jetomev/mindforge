# L1 — the domain tier

Doctrine that is real but **not universal**. Release discipline is irrelevant on a
writing night; craft rules are irrelevant during a package fix. Loading them always
would spend the L0 budget on rules that are idle most of the time.

## Rules for this tier

- **One file per domain.** `release.md`, `aur.md`, `writing.md`, `homelab.md`.
- **~100 lines each.** Richer than L0 is fine — these load only when relevant.
- **Operative rules only.** *What to do.* The story of how the rule was learned
  belongs in L3, where it costs nothing until someone asks why.
- **One fact, one level.** If a rule is here, it is nowhere else. Lower tiers
  point up; they never restate.

## The part people get wrong

**L1 does not load itself.** A file sitting on disk changes nothing. L0 must carry
an explicit instruction to read the domain file *before* acting in that domain —
"read it if it seems necessary" is not a trigger, it is a hope.

## Splitting

When a domain exceeds its budget, split by *when you need it*, not by topic size.
Release and AUR packaging are one subject but two moments: one happens on every
tag, the other only when publishing. Two files.
