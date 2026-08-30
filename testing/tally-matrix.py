#!/usr/bin/env python3
"""Recompute a test-matrix roll-up from the tables themselves.

Why this exists: M-4. A hand-typed summary sitting over a live table goes stale
the moment a cell changes, which is the same failure shape as a stale README over
shipped code. The roll-up gets computed, never typed.

The one rule that matters: THIS SCRIPT REFUSES TO GUESS. A result cell whose
verdict it does not recognise stops the run with exit 1 and prints the cell.
It does not fall back to a default bucket. Silent misclassification is exactly how
a hand tally goes wrong, so teach it the new verdict deliberately -- do not let it
round. (It earned this on 2026-08-30: row 11.9 Desktop reads `PREMISE IS FALSE`,
a verdict no earlier round had produced.)

Two parsing traps, both already paid for:
  * Split rows on UNESCAPED pipes only. Row 8.8 of the v0.1.2 matrix carries an
    escaped pipe in its prose; a naive split shifts every later column.
  * Classify on the LEADING verdict token, not on the whole cell. Result cells in
    §11 carry paragraphs of prose that contain the words "pass" and "fail" in
    ordinary sentences.

Usage:
    python3 testing/tally-matrix.py                    # newest matrix in testing/
    python3 testing/tally-matrix.py <path-to-matrix>
"""

import collections
import glob
import io
import os
import re
import sys

# A §11-style table carries two result columns (one per surface) instead of one.
TWO_COLUMN_SECTIONS = {11}

SPLIT = re.compile(r'(?<!\\)\|')          # unescaped pipes only
ROW = re.compile(r'^\s*\|\s*(\d+)\.(\d+)\s*\|')
SEC = re.compile(r'^##\s*§(\d+)')

# Verdicts this script knows. Anything else stops the run rather than being binned.
# 'deferred' is the only one that does NOT count as a filled cell.
VERDICTS = (
    ('DEFERRED', 'deferred'),
    ('CANNOT DISCRIMINATE', 'cannot'),      # the check cannot fire on this surface
    ('PREMISE IS FALSE', 'premise'),        # observed, filled, not a pass
    ('FAIL', 'fail'),
    ('N/A', 'na'),
    ('PASS', 'pass'),
)
FILLED = ('pass', 'fail', 'na', 'cannot', 'premise')


def classify(cell):
    head = re.sub(r'[*`_]', '', cell).strip()
    head = re.split(r'\s+[-—–]{1,2}\s+', head)[0][:48].upper()
    for token, verdict in VERDICTS:
        if token in head:
            return verdict
    return 'UNPARSED:' + head


def read_cells(path):
    cells = []                                   # (section, row, column, verdict)
    section = None
    for line in io.open(path, encoding='utf-8'):
        m = SEC.match(line)
        if m:
            section = int(m.group(1))
            continue
        m = ROW.match(line)
        if not m or section is None:
            continue
        parts = [p.strip() for p in SPLIT.split(line)]
        if parts and parts[0] == '':
            parts = parts[1:-1]
        row = '%s.%s' % (m.group(1), m.group(2))
        if section in TWO_COLUMN_SECTIONS:       # | # | Check | Expected | Terminal | Desktop |
            cells.append((section, row, 'Terminal', classify(parts[3])))
            cells.append((section, row, 'Desktop', classify(parts[4])))
        else:                                    # | # | Check | Expected | Result | Notes |
            cells.append((section, row, 'Result', classify(parts[3])))
    return cells


def main():
    if len(sys.argv) > 1:
        path = sys.argv[1]
    else:
        here = os.path.dirname(os.path.abspath(__file__))
        found = sorted(glob.glob(os.path.join(here, '*Test Matrix*.md')))
        if not found:
            sys.exit('no matrix found in %s -- pass one as an argument' % here)
        path = found[-1]
    print('matrix: %s\n' % os.path.basename(path))

    cells = read_cells(path)
    if not cells:
        sys.exit('no result rows parsed -- check the table format')

    unparsed = [c for c in cells if c[3].startswith('UNPARSED')]
    if unparsed:
        print('UNPARSED CELLS -- fix the classifier before trusting any number.')
        print('Add the verdict to VERDICTS deliberately; do not let it round.')
        for c in unparsed:
            print('    section %d  %s  %s -> %s' % c)
        sys.exit(1)

    per_sec = collections.defaultdict(collections.Counter)
    for section, _row, _col, verdict in cells:
        per_sec[section][verdict] += 1

    def filled(counter):
        return sum(counter[k] for k in FILLED)

    print('Section roll-up (cells FILLED, not cells passed -- a FAIL is a filled cell):')
    for section in sorted(per_sec):
        c = per_sec[section]
        extra = ', '.join('%d %s' % (c[k], k)
                          for k in ('fail', 'na', 'cannot', 'premise', 'deferred') if c[k])
        print('  section %-3d %2d/%-3d %s' % (section, filled(c), sum(c.values()),
                                              '(%s)' % extra if extra else ''))

    total = collections.Counter()
    for c in per_sec.values():
        total.update(c)
    print('\nTOTAL: %d cells, %d filled, %d deferred' %
          (sum(total.values()), filled(total), total['deferred']))
    print('  pass %d | fail %d | N/A %d | cannot-discriminate %d | premise-false %d | deferred %d'
          % (total['pass'], total['fail'], total['na'],
             total['cannot'], total['premise'], total['deferred']))

    print('\nEvery non-pass cell, so none of them hides inside an aggregate:')
    for section, row, col, verdict in cells:
        if verdict != 'pass':
            print('  section %-3d %-6s %-9s %s' % (section, row, col, verdict))


if __name__ == '__main__':
    main()
