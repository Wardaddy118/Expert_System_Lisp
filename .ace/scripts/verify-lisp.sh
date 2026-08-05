#!/bin/bash
#
# verify-lisp.sh - Common Lisp gate for this project.
#
# Wired into .aceconfig as `verify: test_cmd:` and therefore executed by
# .ace/scripts/verify.sh. It must exit non-zero on any failure, and it must
# also exit non-zero when there is nothing to verify: an empty gate that
# reports success is the exact failure mode the Harness Engineering Standard
# forbids.
#
# What it does today: compile-checks every project Lisp source with SBCL.
# When this project grows an ASDF system with a test system, add the
# `asdf:test-system` call at the bottom (see TODO) so the gate verifies
# behaviour, not just compilability.

set -u

LISP="${LISP:-sbcl}"

if ! command -v "$LISP" >/dev/null 2>&1; then
    echo "[!] $LISP not found on PATH. Install SBCL or set LISP=<implementation>."
    exit 1
fi

# Project sources only: dot-directories (.git, .vscode/alive scratch fasls,
# .ace) and dependency trees are pruned, and quicklisp.lisp is excluded because
# it is the upstream Quicklisp bootstrap installer, not project code.
# -mindepth 1 keeps the '.' starting point itself from matching the '.*' prune.
SOURCES=$(find . -mindepth 1 \
    \( -name '.*' -o -name 'node_modules' -o -name 'quicklisp' \) -prune -o \
    \( -name '*.lisp' -o -name '*.asd' \) -print \
    | sed 's|^\./||' | grep -v '^quicklisp\.lisp$' | sort)

if [ -z "$SOURCES" ]; then
    echo "[!] No project Lisp sources found (*.lisp / *.asd, excluding"
    echo "    quicklisp.lisp). There is nothing to verify, so this gate fails"
    echo "    rather than passing on silence."
    echo "    Add sources, or point verify.test_cmd in .aceconfig at the real"
    echo "    acceptance command for this project."
    exit 1
fi

echo "[*] Compile-checking:"
echo "$SOURCES" | sed 's/^/      /'

# Deliberately a repo-relative scratch dir, not mktemp: SBCL is a native
# Windows binary, so a Git Bash /tmp path reaches it as C:/tmp and fails to
# open. A relative path is understood by both. Ignored via .gitignore.
WORKDIR=".ace/.verify-cache"
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"
trap 'rm -rf "$WORKDIR"' EXIT
STATUS=0

for src in $SOURCES; do
    out="$WORKDIR/$(echo "$src" | tr '/' '_').fasl"
    # compile-file's third value (failure-p) is true only for errors and
    # full WARNINGs; STYLE-WARNINGs (undefined functions across files
    # compiled in isolation) are expected here and are not failures.
    if ! "$LISP" --non-interactive --no-userinit \
        --eval "(let ((*compile-verbose* nil) (*compile-print* nil))
                  (multiple-value-bind (fasl warn fail)
                      (handler-case (compile-file \"$src\" :output-file \"$out\")
                        (error (e) (format *error-output* \"~a~%\" e) (values nil t t)))
                    (declare (ignore fasl warn))
                    (when fail (sb-ext:exit :code 1))))" >"$WORKDIR/log" 2>&1; then
        echo "[!] FAILED: $src"
        sed 's/^/      /' "$WORKDIR/log"
        STATUS=1
    fi
done

if [ "$STATUS" -ne 0 ]; then
    echo "[!] Lisp compile check failed."
    exit 1
fi

echo "[ok] All project Lisp sources compiled cleanly."

# TODO: once an ASDF system exists, replace/extend the above with the real
# behavioural gate, e.g.:
#   sbcl --non-interactive \
#        --eval '(asdf:load-asd (truename "expert-system.asd"))' \
#        --eval '(asdf:test-system :expert-system/tests)'

exit 0
