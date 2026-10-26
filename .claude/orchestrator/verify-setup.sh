#!/usr/bin/env bash
# Mault multi-agent setup verifier (#2464).
#
# Runs from the workspace root. Every check runs; failures are collected and
# reported together with what to do about each. Exit 0 only when nothing failed.
# A check that cannot be determined reports SKIP, never OK.
set -u

# BUILTINS ONLY, DELIBERATELY. A setup verifier is the thing you run when a
# workspace is already in a bad state, so it should depend on as little as it can.
# Every check below uses bash builtins -- parameter expansion instead of dirname,
# a glob instead of ls, `[` and printf -- so the only externals are the JSON parser
# and the platform CLI, and BOTH are already probed with command -v and reported as
# SKIP when absent. The script therefore produces a correct, honest report even on
# a PATH with nothing on it at all.
self="${BASH_SOURCE[0]}"
# BOTH separators. `dirname` accepted a backslashed path and the first
# parameter-expansion replacement did not -- it matched only `/`, so a Windows-shaped
# invocation left selfdir as "." and ROOT resolved to the filesystem root, failing
# every check with a path beginning "//". Replacing an external with a builtin drops
# whatever that external was quietly handling, and this is what it was handling.
selfdir="${self%[/\\]*}"
[ "$selfdir" = "$self" ] && selfdir="."
ROOT="$(cd "$selfdir/../.." 2>/dev/null && pwd)" || ROOT="$selfdir/../.."
failures=0

ok()   { printf "  OK    %s\n" "$1"; }
skip() { printf "  SKIP  %s -- %s\n" "$1" "$2"; }
fail() { printf "  FAIL  %s\n        %s\n" "$1" "$2" >&2; failures=$((failures + 1)); }

printf "Mault multi-agent setup -- verifying %s\n\n" "$ROOT"

# 1. settings.json present and parses.
#
#    THE TWO HALVES ARE SEPARATE BECAUSE ONLY ONE OF THEM IS ALWAYS ANSWERABLE.
#    Presence is a shell test and can always be decided. Parsing needs a JSON
#    parser, and on a machine with neither node nor python3 there is no parser to
#    ask -- which is NOT the same fact as "the file is invalid". The first cut
#    collapsed them and reported a perfectly valid settings.json as
#    "does not parse as JSON (invalid)" whenever the parser was missing: a claim
#    no value the script read produced. This file already states the rule for the
#    platform check -- indeterminate is SKIP, never OK -- and the rule holds in
#    both directions: indeterminate is never FAIL either.
settings="$ROOT/.claude/settings.json"
if [ ! -f "$settings" ]; then
  fail "settings.json present" "$settings is missing. Re-provision the workspace from the Mault panel."
elif [ ! -r "$settings" ]; then
  # THE THIRD STATE, and the third time this one class has bitten in this file.
  # An unreadable file is not an invalid one. The parse probe suppresses stderr, so
  # a permission error came back as a non-zero exit indistinguishable from a syntax
  # error and the script reported "does not parse as JSON (invalid)" -- sending the
  # reader to fix content that may be perfectly fine. Same shape as reporting a
  # missing parser as invalid JSON, and as reporting an unavailable platform CLI
  # as a passing check: a verdict the script did not earn from anything it read.
  ok "settings.json present"
  fail "settings.json parses" "$settings exists but cannot be READ (permissions). This is not a claim about its contents. Fix its permissions, then re-run."
else
  ok "settings.json present"
  json_parser=""
  if command -v node >/dev/null 2>&1; then json_parser="node"
  elif command -v python3 >/dev/null 2>&1; then json_parser="python3"
  fi
  if [ -z "$json_parser" ]; then
    skip "settings.json parses" "no JSON parser on PATH (neither node nor python3), so this could not be checked -- it is NOT a claim that the file is invalid"
  elif [ "$json_parser" = "node" ] \
       && ! node -e "JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'))" "$settings" >/dev/null 2>&1; then
    fail "settings.json parses" "$settings does not parse as JSON (invalid). Fix or re-provision it."
  elif [ "$json_parser" = "python3" ] \
       && ! python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$settings" >/dev/null 2>&1; then
    fail "settings.json parses" "$settings does not parse as JSON (invalid). Fix or re-provision it."
  else
    ok "settings.json parses"
  fi
fi

# 2. hooks deployed. An EMPTY directory is a failure, not a pass: the directory is
#    created by provisioning before anything is written into it, so its existence
#    proves nothing about whether the hooks arrived.
hooks="$ROOT/.claude/hooks"
if [ ! -d "$hooks" ]; then
  fail "hooks deployed" "$hooks is missing. Re-provision the workspace from the Mault panel."
elif hook_entries=("$hooks"/*) && [ ! -e "${hook_entries[0]}" ]; then
  fail "hooks deployed" "$hooks is empty. Re-provision the workspace; hooks are not optional."
else
  ok "hooks deployed"
fi

# 3. sessions directory writable. Probed by WRITING, not by testing a mode bit:
#    permission semantics differ across the platforms this ships to, and a check
#    that only means something on one of them is a check that silently stops.
sessions="$ROOT/.mault/sessions"
if [ ! -d "$sessions" ]; then
  fail "sessions directory writable" "$sessions is missing. Create it and make it writable by your user."
else
  probe="$sessions/.mault-verify-probe.$$"
  if ( : > "$probe" ) 2>/dev/null; then
    # Best-effort cleanup. `rm` is the one external left and its absence must not
    # change the verdict -- the WRITE already answered the question.
    rm -f "$probe" 2>/dev/null || true
    ok "sessions directory writable"
  else
    fail "sessions directory writable" "cannot write to $sessions. Fix its permissions; session identity is written here."
  fi
fi

# 4. platform CLI reachable. NEITHER INSTALLED IS A SKIP, NOT AN OK -- a check that
#    could not be performed must never report as one that passed.
if command -v gh >/dev/null 2>&1; then
  ok "platform CLI reachable (gh)"
elif command -v az >/dev/null 2>&1; then
  ok "platform CLI reachable (az)"
else
  skip "platform CLI reachable" "neither gh nor az is on PATH; install the one for your platform to enable merge governance"
fi

if [ "$failures" -ne 0 ]; then
  printf "\n%s check(s) FAILED. Each is named above with what to do about it.\n" "$failures" >&2
  exit 1
fi
printf "\nAll checks passed.\n"
