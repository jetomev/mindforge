#!/usr/bin/env python3
"""mindForge boards: every project's page beside the chat (the maintainer, 2026-10-22: "for all projects we
have, the same page we have opened on the side for KognogOS… opened as soon as we call a project").

A project's TODO.md stays the record (git keeps it, every rule points at it). Its board is a picture of it:
each "## section" with checkboxes becomes a stage, each "- [ ]" / "- [x]" a step. The page itself
(boards/board.html) is one generic Artifact per project; its data lives in that Artifact's database:
`meta/config` (the title) and `stages/<key>` (the steps, with done marks and notes).

    board.py build  <project-dir> <out-dir>    the database documents for <project-dir>'s TODO.md, as files
                                               (out-dir/meta/config.json, out-dir/stages/sNN.json) to send with
                                               ArtifactData batch; every step keeps the note/done mark the
                                               board gave it when --from <export-dir> is passed; --badges <file>
                                               ({step id: label}) puts a small label on those steps, e.g.
                                               "KognogOS 1.0 · stage 03" from KognogOS's scripts/board-links.py
    board.py status <project-dir>              the banner `mindforge active` prints: the BOARD line first, then
                                               each stage's progress and what's next — read live from TODO.md
    board.py pull   <project-dir> <export-dir> ticks and new steps made on the board, written back into TODO.md

The board's address is the one line in <project-dir>/.board. Python standard library only.
"""
from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path

CHECK = re.compile(r"^(\s*)- \[([ xX])\] (.*)$")
HEAD = re.compile(r"^(#{2,3}) (.+?)\s*$")


def plain(text: str) -> str:
    """Markdown → plain words for the page: links to their text, no bold/italic/code marks."""
    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)
    text = re.sub(r"\*\*|__|`", "", text)
    text = re.sub(r"(?<!\w)\*(?!\s)|(?<!\s)\*(?!\w)", "", text)
    return re.sub(r"\s+", " ", text).strip()


def split_title(text: str) -> tuple[str, str]:
    """A step's title (its first sentence, or the part before a long dash/colon) and the rest as detail."""
    words = plain(text)
    m = re.match(r"^(.{20,160}?)(?:\s[—–]\s|:\s|\.\s)(.+)$", words)
    if m and len(words) > 110:
        return m.group(1).rstrip(" .:"), m.group(2)[:600]
    if len(words) > 160:
        return words[:157].rsplit(" ", 1)[0] + "…", words[:600]
    return words, ""


def step_id(stage: str, text: str) -> str:
    return hashlib.sha1((stage + "\0" + plain(text)[:80]).encode()).hexdigest()[:10]


def parse(todo: Path) -> tuple[str, list[dict]]:
    """TODO.md → (title, stages). A stage is a ## heading (### under it folds in) holding checkboxes."""
    lines = todo.read_text(errors="replace").splitlines()
    title = next((plain(l[2:]) for l in lines if l.startswith("# ")), todo.parent.name)
    stages, cur = [], None
    for n, line in enumerate(lines):
        h = HEAD.match(line)
        if h:
            if h.group(1) == "##" or cur is None:
                cur = {"name": plain(h.group(2)), "items": [], "line": n}
                stages.append(cur)
            continue
        m = CHECK.match(line)
        if m and cur is None:          # steps above the first heading are steps too, in a stage of their own
            cur = {"name": "Now", "items": [], "line": n}
            stages.append(cur)
        if m and cur is not None:
            depth = min(len(m.group(1).expandtabs(2)) // 2, 3)
            t, d = split_title(m.group(3))
            cur["items"].append({"id": step_id(cur["name"], m.group(3)), "title": t, "detail": d,
                                 "done": m.group(2) in "xX", "depth": depth, "line": n,
                                 "indent": len(m.group(1).expandtabs(2))})
            continue
        # a line indented under a step, not a step itself, is that step's progress: it joins the step's detail
        # (2026-10-28: progress went on sub-lines so a step's id holds, and no board ever showed it)
        last = cur["items"][-1] if cur and cur["items"] else None
        text = line.strip()
        if last and text and len(line) - len(line.lstrip()) > last["indent"]:
            text = re.sub(r"^[-*] ", "", text)
            last["detail"] = f"{last['detail']} · {text}" if last["detail"] else text
    return title, [s for s in stages if s["items"]]


def build(project: Path, out: Path, export: Path | None, badges: Path | None = None) -> int:
    title, stages = parse(project / "TODO.md")
    labels = json.loads(badges.read_text()) if badges and badges.exists() else {}
    kept = {}
    if export and (export / "stages").is_dir():          # notes and board-only marks survive a rebuild
        for f in (export / "stages").glob("*.json"):
            d = json.loads(f.read_text()); d = d.get("data", d)
            for it in d.get("items", []):
                kept[it["id"]] = it
    (out / "meta").mkdir(parents=True, exist_ok=True)
    (out / "stages").mkdir(parents=True, exist_ok=True)
    (out / "meta/config.json").write_text(json.dumps({"title": title, "project": project.name,
                                                      "source": "TODO.md", "stages": len(stages)}, ensure_ascii=False))
    for i, s in enumerate(stages):
        items = []
        for it in s["items"]:
            old = kept.get(it["id"], {})
            item = {k: it[k] for k in ("id", "title", "detail", "done", "depth")}
            for k in ("note", "doneAt"):
                if old.get(k):
                    item[k] = old[k]
            if labels.get(it["id"]):
                item["badge"] = labels[it["id"]]
            items.append(item)
        (out / f"stages/s{i:02d}.json").write_text(json.dumps({"order": i, "name": s["name"], "items": items},
                                                              ensure_ascii=False))
    print(f"board.py build: {title} — {len(stages)} stages, {sum(len(s['items']) for s in stages)} steps → {out}")
    return 0


def status(project: Path) -> int:
    board = (project / ".board").read_text().strip() if (project / ".board").exists() else None
    title, stages = parse(project / "TODO.md")
    total = sum(len(s["items"]) for s in stages)
    done = sum(it["done"] for s in stages for it in s["items"])
    print(f"\n╭─ {title}")
    if board:
        print(f"│  BOARD — open it beside the chat FIRST (Artifact open): {board}")
    else:
        print("│  (no board yet — mindForge boards: board.py build, then publish boards/board.html)")
    print(f"│  {done} of {total} steps done · read live from TODO.md")
    print("╰─" + "─" * 60)
    now = None
    for s in stages:
        d = sum(it["done"] for it in s["items"]); n = len(s["items"])
        mark = "✅" if d == n else ("🔄" if d else "⬜")
        if now is None and d < n:
            now = s
        print(f"  {mark} {s['name'][:48]:<48} {d}/{n}")
    if now:
        todo = [it for it in now["items"] if not it["done"]]
        print(f"\n  NEXT — {now['name'][:70]}")
        for it in todo[:5]:
            print(f"    □ {it['title'][:96]}")
        if len(todo) > 5:
            print(f"    … {len(todo) - 5} more here")
    return 0


def pull(project: Path, export: Path) -> int:
    """Ticks made on the board → "- [x]" in TODO.md; steps added on the board → new lines under their stage."""
    todo = project / "TODO.md"
    lines = todo.read_text(errors="replace").splitlines()
    _, stages = parse(todo)
    by_id = {it["id"]: it for s in stages for it in s["items"]}
    by_name = {s["name"]: s for s in stages}
    ticked, added = 0, []
    for f in sorted((export / "stages").glob("*.json")):
        d = json.loads(f.read_text()); d = d.get("data", d)
        for it in d.get("items", []):
            src = by_id.get(it.get("id"))
            if src and it.get("done") and not src["done"]:
                lines[src["line"]] = re.sub(r"- \[ \]", "- [x]", lines[src["line"]], count=1); ticked += 1
            elif src is None and it.get("added"):
                st = by_name.get(d.get("name"))
                if st:
                    last = max(i["line"] for i in st["items"])
                    added.append((last, f"- [{'x' if it.get('done') else ' '}] {it['title']} *(added on the board)*"))
    for last, text in sorted(added, reverse=True):
        lines.insert(last + 1, text)
    todo.write_text("\n".join(lines) + "\n")
    print(f"board.py pull: {ticked} ticked, {len(added)} added → {todo}")
    return 0


def main(argv: list[str]) -> int:
    if len(argv) >= 2 and argv[0] == "status":
        return status(Path(argv[1]).expanduser())
    if len(argv) >= 3 and argv[0] == "build":
        exp = Path(argv[argv.index("--from") + 1]) if "--from" in argv else None
        bad = Path(argv[argv.index("--badges") + 1]) if "--badges" in argv else None
        return build(Path(argv[1]).expanduser(), Path(argv[2]), exp, bad)
    if len(argv) >= 3 and argv[0] == "pull":
        return pull(Path(argv[1]).expanduser(), Path(argv[2]))
    sys.exit(__doc__)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
