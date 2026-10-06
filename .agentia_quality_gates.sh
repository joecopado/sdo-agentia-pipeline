#!/usr/bin/env bash
# Local Agentia quality gates for this project (macOS / Linux).
# Agentia runs this from the repo root during `agentia cicd work test` and `agentia cicd work submit`;
# it must exit non-zero when a check fails. Kept small on purpose, and every check looks only at what
# the story changed (the files on this branch since the base branch), not the whole baseline:
#   1. Code Analyzer (Recommended rules) on the changed source files; fails on a Critical or High finding.
#   2. Apex tests, only when the story changes Apex: the classes in AGENTIA_APEX_TEST_CLASSES, else the
#      changed classes whose names end in Test. They run in the project's target org (your dev org).
#   3. LWC Jest, only when the project has a package.json and LWC components.
set -euo pipefail

# Code Analyzer's PMD, CPD and SFGE engines need Java 11+, its Flow engine Python 3.10+. macOS ships a
# Java stub and Python 3.9, so use a Homebrew JDK / Python when the system ones are not usable.
if ! /usr/libexec/java_home >/dev/null 2>&1 && [[ -x /opt/homebrew/opt/openjdk/bin/java ]]; then
  export JAVA_HOME=/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home
  export PATH="$JAVA_HOME/bin:$PATH"
fi
if ! python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)' 2>/dev/null; then
  for py in python3.13 python3.12 python3.11 python3.10; do
    if command -v "$py" >/dev/null 2>&1; then
      shim="$(mktemp -d)"; ln -s "$(command -v "$py")" "$shim/python3"; export PATH="$shim:$PATH"; break
    fi
  done
fi

base="${AGENTIA_BASE_BRANCH:-main}"
git fetch --quiet origin "$base" 2>/dev/null || true
changed=()
while IFS= read -r f; do [[ -n "$f" && -f "$f" ]] && changed+=("$f"); done \
  < <(git diff --name-only --diff-filter=ACMR "origin/$base...HEAD" -- force-app)
if [[ ${#changed[@]} -eq 0 ]]; then
  echo "## No source changes on this branch since origin/$base: nothing to check"
  exit 0
fi
echo "## Changed source files (${#changed[@]}):"; printf '   %s\n' "${changed[@]}"

echo "## Running Code Analyzer (Recommended rules, fail on Critical/High)"
targets=(); for f in "${changed[@]}"; do targets+=(--target "$f"); done
sf code-analyzer run --workspace force-app "${targets[@]}" --severity-threshold 2 --view table

apex_changed=0
for f in "${changed[@]}"; do [[ "$f" == *.cls || "$f" == *.trigger ]] && apex_changed=1; done
if [[ $apex_changed -eq 1 ]]; then
  if [[ -n "${AGENTIA_APEX_TEST_CLASSES:-}" ]]; then
    # shellcheck disable=SC2206
    tests=(${AGENTIA_APEX_TEST_CLASSES//,/ })
  else
    tests=()
    for f in "${changed[@]}"; do n="$(basename "$f" .cls)"; [[ "$f" == *.cls && "$n" == *Test ]] && tests+=("$n"); done
  fi
  if [[ ${#tests[@]} -eq 0 ]]; then
    echo "## Apex changed but no test class named (set AGENTIA_APEX_TEST_CLASSES or add a *Test class)"; exit 1
  fi
  echo "## Running Apex tests in the target org: ${tests[*]}"
  sf apex run test --class-names "${tests[@]}" --code-coverage --result-format human --wait 10
else
  echo "## No Apex changed: Apex tests not needed"
fi

if [[ -f package.json ]] && find force-app -type d -name lwc -print -quit | grep -q .; then
  echo "## Running LWC tests"
  npx sfdx-lwc-jest -- --passWithNoTests
else
  echo "## No LWC components: LWC tests not needed"
fi
echo "## Local quality gates passed"
