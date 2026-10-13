#!/usr/bin/env bash
# make-bisect-repo.sh — Lab 03, Task 5.
#
# Creates ./regression-demo, a small repository with 16 commits. Somewhere in
# that history a change broke the transform script. Your job in Task 5 is to
# find WHICH commit, using git bisect — not by reading the diffs.
#
# Run it once:   bash make-bisect-repo.sh
# Start over:    rm -rf regression-demo && bash make-bisect-repo.sh

set -euo pipefail

REPO=regression-demo
if [ -e "$REPO" ]; then
  echo "ERROR: $REPO already exists. Remove it first:  rm -rf $REPO" >&2
  exit 1
fi

mkdir "$REPO"
cd "$REPO"
git init -q -b main .
git config user.name  "Pipeline Team"
git config user.email "team@novasoft.example"

cat > input.txt <<'TXT'
payment-service
auth-service
cart-service
search-service
TXT

# the good implementation
write_transform_good() {
  cat > transform.sh <<'TXT'
#!/usr/bin/env bash
# Uppercase every line of input.txt into output.txt
set -euo pipefail
tr '[:lower:]' '[:upper:]' < input.txt > output.txt
TXT
  chmod +x transform.sh
}

# the broken implementation: an "optimisation" that silently drops the last line
write_transform_bad() {
  cat > transform.sh <<'TXT'
#!/usr/bin/env bash
# Uppercase every line of input.txt into output.txt
set -euo pipefail
# speed-up: drop the trailing blank line before transforming
sed '$d' input.txt | tr '[:lower:]' '[:upper:]' > output.txt
TXT
  chmod +x transform.sh
}

commit() { git add -A && GIT_COMMITTER_DATE="$2" GIT_AUTHOR_DATE="$2" git commit -q -m "$1"; }

write_transform_good
echo "# Pipeline" > README.md
commit "Add transform script and sample input" "2026-02-02T09:00:00"

MSGS=(
  "Document the transform step in the README"
  "Add search-service to the input list"
  "Tidy whitespace in README"
  "Record the expected output format"
  "Note the uppercase rule in the README"
  "Add a usage line to the README"
)
d=3
for m in "${MSGS[@]}"; do
  echo "- $m" >> README.md
  commit "$m" "2026-02-0${d}T09:00:00"
  d=$((d+1))
done

# --- the regression goes in here, in the middle of the history ---
write_transform_bad
echo "- Speed up the transform step" >> README.md
commit "Speed up the transform step" "2026-02-09T09:00:00"

MSGS2=(
  "Add a contributing section to the README"
  "Fix a typo in the README"
  "Mention the output file in the README"
  "Add a licence note"
  "Reword the usage line"
  "Add a troubleshooting heading"
  "Link the team wiki"
  "Final README tidy-up"
)
d=10
for m in "${MSGS2[@]}"; do
  echo "- $m" >> README.md
  commit "$m" "2026-02-${d}T09:00:00"
  d=$((d+1))
done

echo
echo "Created $REPO with $(git rev-list --count HEAD) commits on main."
echo "Somewhere in there, transform.sh started dropping a line. Find it."
