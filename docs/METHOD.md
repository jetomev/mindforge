# The method

mindForge is a method with a reference implementation. The scripts are a few
hundred lines of shell that anyone could rewrite in an afternoon. This document
is the part that took a year of real mistakes to learn.

It assumes you work with an AI assistant repeatedly, on real projects, over
months — not one-off questions.

---

## The problem

Two failures show up in every long-running collaboration with an AI assistant,
and they look the same from the outside.

**Across sessions,** the assistant forgets how you work. Not facts — those are
easy to store — but *rules*. The working agreement gets restated, drifts, and
quietly degrades.

**Within a session,** it drifts. Three hours in, deep in something that is
working, the careful pacing you agreed on erodes. Commands get batched.
Explanations get skipped. You end up being the one who notices.

Most advice for this is "write better instructions." That advice is wrong, and
the reason it is wrong is the foundation of everything below.

---

## 1. The tier pyramid

Assistant memory is usually one undifferentiated pile: facts, history, and
rules together, retrieved when something looks relevant. That works for facts
and fails for rules, because **retrieval is selective by design.** A rule that
applies only when recalled is not a rule. It is a suggestion with good odds.

Split by *when it must be true*, not by topic:

| Tier | Loaded | Budget | Holds |
|---|---|---|---|
| **L0** | always, every session | **~60 lines, hard** | rules that must never lapse |
| **L1** | on demand, by domain | ~100 lines each | doctrine for one kind of work |
| **L2** | when in that project | ~80 lines | how *this* project builds and ships |
| **L3** | on demand | unbounded | history, decisions, why |

L0 is expensive: every line is paid for in every session, forever. That expense
is the point — it forces the question *does this genuinely apply everywhere?*

Most things do not. Release discipline is irrelevant on a writing day. Craft
rules are irrelevant during a bug fix. They belong at L1, where they cost
nothing until the day they matter.

---

## 2. Two laws

**One fact, one level.** If a rule is at L0, it exists nowhere else. Two copies
drift by a word, and then the assistant follows one of them and neither of you
knows which. Lower tiers point upward; they never restate.

**Promotion requires demotion.** The L0 budget is hard. Something new at the top
means something else comes down. Without this, every individually-important rule
migrates upward, L0 becomes three hundred lines, and a rule buried among forty
others carries less force than one standing among ten.

**Dilution looks exactly like drift.** You will diagnose it as the assistant
getting worse. It is you having made the top tier unreadable.

---

## 3. Nothing loads itself

A file on disk changes nothing. Context injected without an instruction changes
nothing. Both feel like they should work, and both quietly do not.

We hit this twice in one day:

- L1 files sat on disk, correct and unread, until L0 gained an explicit line:
  *read the domain file before acting in its domain — not after, not if it
  seems necessary.*
- The session briefing was injected into context at session start. The
  assistant ignored it and re-derived the same facts with seven tool calls,
  while the human saw nothing at all. The fix was not better data. It was a
  directive attached to the data saying what to do with it.

**"Read it when relevant" is not a trigger. It is a hope.**

---

## 4. Symmetry, and the floor

A session-start briefing is worth exactly what the previous session wrote down.
Build the closeout first, or the briefing will one day show a confident, thin,
wrong picture — and the moment it is wrong once, it is dead.

Three mechanisms, and the third is the one that matters:

- **`brief`** — what is true right now, at session start
- **`wrap`** — the deliberate closeout you run when you finish
- **a session-end hook** — the floor, which runs whether or not you remembered

Without the floor, your log records only the sessions you bothered to close,
which is precisely the sessions that needed no record. The floor writes a thin
row — start, end, *not wrapped* — and that row is honest. A gap in the log is
worse than an unflattering entry.

---

## 5. Structure over reminders

This is the load-bearing idea. Everything else is an application of it.

The origin: a package manager printed `Proceed with installation? [Y/n]` at a
point where the user reasonably expected a different program to be asking. He
answered it wrong three times. Twice we responded by explaining more carefully.
The third time we renamed the prompt to `Begin the handoff?` and the problem
disappeared permanently.

> **When a human keeps getting something wrong, change the design — not the
> instructions.**

Applied to the collaboration itself: rather than *remembering* to hand over one
command at a time, every handover goes through a fixed shape —

1. **Intro** — what this does, and why now
2. **The command** — one, fenced, short enough not to wrap
3. **Expected result** — so they compare instead of guess
4. **Stop** — wait for real output

The shape is the point. A skipped step is *visible on screen*. Drift stops being
something the human must notice and becomes something both parties can see.

---

## 6. Instrument drift instead of arguing about it

When you catch the assistant straying, you have two options. Explain again — or
log it.

`drift "batched three commands in one turn"` costs one line and a timestamp.
After a month you do not have impressions, you have a distribution: drift
clusters after compaction, or at hour three, or on release days. Then you fix
the *cause*, which is usually structural, instead of relitigating the rule.

An unlogged correction teaches nothing twice.

---

## 7. Never trust discipline with secrets

If any of this becomes public, the templates and your filled-in instances must
be different artifacts, and the separation must be **mechanical**.

Ship templates with placeholders. Generate the real files locally. Gitignore
them by location. Then put a pre-commit hook in front of everything that fails
the commit — not the review — on personal data, with two layers:

- **Generic patterns**, safe to publish, that name *shapes*: an email, a private
  IP, key material, a real home path.
- **A local wordlist** of literal terms — names, hostnames — which is itself
  personal data and therefore lives outside the repo.

On the day we built this, the hook refused two commits. Neither was a test.
Both were genuine mistakes, made while being careful, by someone who had written
the rule an hour earlier. That is the entire argument: **you cannot be careful
enough, often enough, forever.**

---

## 8. Rot is silent

Things that break announce themselves. Things that rot do not — nothing fails,
so nothing tells you.

A packaging file sat two versions behind for weeks. Once that was caught, a
version check was added. Later the same file diverged again — this time in
*content*, while the version matched — so the check passed it every time. It
would have shipped an unsigned artifact from a project whose entire premise was
signed artifacts.

Check the things that fail silently, on a schedule you do not control:
version drift, content divergence, unpushed work, orphaned notes, budgets
exceeded. Then add the rule that makes it stick:

> **Anything red for three sessions running stops being a table row and becomes
> a demand.**

Otherwise you build a dashboard you learn to ignore.

---

## What we can honestly claim

mindForge is days old. Here is the evidence, and its limits.

**On the first day it was used, it caught three real defects** — two personal-data
leaks in commits written by the person who had just written the anti-leak rule,
and one content divergence in a packaging file that a version check had passed
repeatedly.

**Every part of it was validated live**, not asserted: the always-loaded tier was
tested with a question whose answer existed nowhere else; the domain trigger was
tested by asking for a fact only the domain file held; the session-end floor was
tested by closing a session without wrapping it.

**Two of the day's findings were bugs in mindForge itself**, found by a fresh
session reading its own briefing.

**The limits:** one machine, one user, one assistant, days of data. The drift log
is empty, so section 6 is a designed mechanism rather than a demonstrated
result. Nothing here has survived a month yet.

We publish it early and say so, because a method that hides its own age is not
a method worth adopting.
