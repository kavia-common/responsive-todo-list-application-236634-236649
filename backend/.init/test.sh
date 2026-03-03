#!/usr/bin/env bash
set -euo pipefail
WORKDIR="/home/kavia/workspace/code-generation/responsive-todo-list-application-236634-236649/backend"
cd "$WORKDIR"
# prefer local jest if present
if [ -x ./node_modules/.bin/jest ]; then
  CI=1 ./node_modules/.bin/jest --runInBand --silent || { echo "TESTS_FAILED" >&2; exit 20; }
elif node -e "const p=require('./package.json'); process.stdout.write((p.scripts&&p.scripts.test)?'1':'0')" | grep -q 1; then
  CI=1 npm run test --silent || { echo "TESTS_FAILED" >&2; exit 20; }
else
  echo "NO_TESTS"; exit 0
fi
echo "TESTS_OK"
