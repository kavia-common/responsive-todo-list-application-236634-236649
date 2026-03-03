#!/usr/bin/env bash
set -euo pipefail
WORKDIR="/home/kavia/workspace/code-generation/responsive-todo-list-application-236634-236649/backend"
cd "$WORKDIR"
[ -f package.json ] || { echo "ERROR: package.json missing" >&2; exit 3; }
node -e "const p=require('./package.json'); if(!p.scripts||!p.scripts.build){console.error('ERROR: package.json missing build script'); process.exit(1);}" || { echo "ERROR: build script missing" >&2; exit 14; }
npm run build --silent > /tmp/build.log 2>&1 || { echo "ERROR: build failed; see /tmp/build.log" >&2; sed -n '1,200p' /tmp/build.log >&2 || true; exit 15; }
# Emit success marker
echo "BUILD_OK"
