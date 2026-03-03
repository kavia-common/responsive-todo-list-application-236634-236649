#!/usr/bin/env bash
set -euo pipefail
# install-dependencies step: non-interactive npm install/ci and validations
WORKDIR="/home/kavia/workspace/code-generation/responsive-todo-list-application-236634-236649/backend"
[ -d "$WORKDIR" ] || { echo "ERROR: workspace $WORKDIR missing" >&2; exit 2; }
cd "$WORKDIR"
[ -f package.json ] || { echo "ERROR: package.json missing; run scaffold step" >&2; exit 6; }
LOG=/tmp/install.log
if [ -f package-lock.json ]; then
  npm ci --no-audit --no-fund >"$LOG" 2>&1 || { echo "ERROR: npm ci failed; see $LOG" >&2; sed -n '1,200p' "$LOG" >&2 || true; exit 9; }
else
  npm i --no-audit --no-fund >"$LOG" 2>&1 || { echo "ERROR: npm install failed; see $LOG" >&2; sed -n '1,200p' "$LOG" >&2 || true; exit 10; }
fi
# concise Node check for react and react-dom in deps or devDeps
node -e "const p=require('./package.json'); const has=(n)=>!!((p.dependencies&&p.dependencies[n])||(p.devDependencies&&p.devDependencies[n])); if(!has('react')||!has('react-dom')){console.error('ERROR: package.json missing react or react-dom'); process.exit(1)}" || { echo "ERROR: react/react-dom missing in package.json" >&2; exit 11; }
[ -d node_modules ] || { echo "ERROR: node_modules missing after install" >&2; exit 12; }
[ -d node_modules/.bin ] || { echo "ERROR: node_modules/.bin missing after install" >&2; exit 13; }
# ensure serve local binary exists since validation prefers local serve
if [ -x ./node_modules/.bin/serve ]; then
  echo "SERVE_OK"
else
  echo "ERROR: node_modules/.bin/serve not found; ensure 'serve' is in devDependencies" >&2; exit 14
fi
echo "DEPS_OK"
exit 0
