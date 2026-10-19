# L1 — scripts that destroy

*Load before writing any script that deletes, resets, drops, wipes, reformats or
re-initialises. Operative rules only; the story is in mindForge's METHOD.md, §9.*

## Every destructive script
1. **Back up first**, to a path the script prints.
2. **Gate on the measurement.** A count taken to decide whether destruction is
   safe must stop the script when it is not zero:
   ```bash
   n=$(count_what_would_be_lost)
   if [ "$n" -gt 0 ] && [ "${FORCE:-}" != "yes" ]; then
     echo "!! $n would be lost. Re-run with FORCE=yes if you mean it."; exit 1
   fi
   ```
   A count that is printed and then ignored is a receipt, not a safeguard.
3. **Move aside, never delete.** `mv data "data.reset-$(date +%Y%m%d-%H%M%S)"`.
   The moved-aside copy is how the cause gets found afterwards.
4. **Do the smallest fix first.** If one setting explains the symptom, change the
   setting and re-test before any reset.

## Hazards
A hazard written in a decision record becomes an assertion in the script that
needs it. Until then it is a `HAZARD:` line in the project's docs, and
`mindforge hazards <project> <what you are touching>` lists it before you act.
