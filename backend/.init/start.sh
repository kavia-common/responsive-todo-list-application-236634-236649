#!/usr/bin/env bash
set -euo pipefail
WORKDIR="/home/kavia/workspace/code-generation/responsive-todo-list-application-236634-236649/backend"
cd "$WORKDIR"
PORT=${PORT:-3000}
LOG=/tmp/serve_out.log
PIDFILE=/tmp/serve.pid
PGFILE=/tmp/serve.pgid
# choose serve binary
if [ -x ./node_modules/.bin/serve ]; then
  SERVE_BIN="./node_modules/.bin/serve"
elif command -v serve >/dev/null 2>&1; then
  SERVE_BIN="$(command -v serve)"
else
  echo "ERROR: 'serve' binary not found locally or globally; ensure 'serve' is installed" >&2; exit 16
fi
# start serve in new process group when possible
if command -v setsid >/dev/null 2>&1; then
  setsid "$SERVE_BIN" -s build -l 0.0.0.0:$PORT >"$LOG" 2>&1 &
else
  "$SERVE_BIN" -s build -l 0.0.0.0:$PORT >"$LOG" 2>&1 &
fi
SERVE_PID=$!
sleep 0.2
if ! kill -0 "$SERVE_PID" >/dev/null 2>&1; then echo "ERROR: serve process died immediately; tail $LOG" >&2; sed -n '1,200p' "$LOG" >&2 || true; exit 17; fi
# record PID and PGID if available
echo "$SERVE_PID" > "$PIDFILE"
PGID=$(ps -o pgid= -p "$SERVE_PID" 2>/dev/null | tr -d ' ' || true)
if [ -n "$PGID" ]; then echo "$PGID" > "$PGFILE"; fi
# report
echo "SERVE_STARTED pid=$SERVE_PID pgid=${PGID:-}"
