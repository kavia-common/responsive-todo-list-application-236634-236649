#!/usr/bin/env bash
set -euo pipefail
# scaffold: create CRA app if workspace empty and package.json missing
WORKDIR="/home/kavia/workspace/code-generation/responsive-todo-list-application-236634-236649/backend"
[ -d "$WORKDIR" ] || { echo "ERROR: workspace $WORKDIR missing" >&2; exit 2; }
cd "$WORKDIR"
# if package.json exists, skip
[ -f package.json ] && { echo "SCAFFOLD_SKIPPED: package.json exists"; exit 0; }
# refuse to scaffold into non-empty workspace (except dotfiles)
shopt -s nullglob
files=("$WORKDIR"/*)
count=0
for f in "${files[@]}"; do
  [ -e "$f" ] || continue
  base=$(basename "$f")
  case "$base" in
    .* ) ;; # ignore dotfiles
    * ) count=$((count+1));;
  esac
done
if [ "$count" -gt 0 ]; then
  echo "ERROR: workspace not empty; aborting scaffold to avoid clobbering" >&2
  exit 3
fi
TMPLOG=/tmp/scaffold.log
export CI=1
export SKIP_PREFLIGHT_CHECK=1
# prefer preinstalled create-react-app; npx fallback only if ALLOW_NETWORK=1
if command -v create-react-app >/dev/null 2>&1; then
  create-react-app . --use-npm >"$TMPLOG" 2>&1 || { echo "ERROR: create-react-app failed; see $TMPLOG" >&2; sed -n '1,200p' "$TMPLOG" >&2 || true; exit 5; }
else
  if [ "${ALLOW_NETWORK:-0}" = "1" ]; then
    # explicit network fallback allowed by env
    npx create-react-app@latest . --use-npm >"$TMPLOG" 2>&1 || { echo "ERROR: npx create-react-app failed; see $TMPLOG" >&2; sed -n '1,200p' "$TMPLOG" >&2 || true; exit 6; }
  else
    echo "ERROR: create-react-app global binary not found and network fallback disabled (set ALLOW_NETWORK=1 to permit npx)" >&2
    exit 7
  fi
fi
# ensure package.json exists
[ -f package.json ] || { echo "ERROR: scaffolding did not produce package.json; see $TMPLOG" >&2; exit 8; }
# add 'serve' to devDependencies only if missing
node -e "const fs=require('fs');const p=JSON.parse(fs.readFileSync('package.json'));
const dd=p.devDependencies||{}; if(!dd.serve){p.devDependencies=Object.assign({},dd,{serve:'latest'});fs.writeFileSync('package.json',JSON.stringify(p,null,2));console.log('ADDED_SERVE')}" > /tmp/scaffold_node_out 2>&1 || true
# final message
echo "SCAFFOLD_OK"
exit 0
