#!/usr/bin/env bash
set -euo pipefail
WORKDIR="/home/kavia/workspace/code-generation/responsive-todo-list-application-236634-236649/backend"
cd "$WORKDIR"
[ -f package.json ] || { echo "ERROR: package.json missing" >&2; exit 3; }
# load persisted env if available (non-fatal)
[ -f /etc/profile.d/node_env.sh ] && . /etc/profile.d/node_env.sh || true
PORT=${PORT:-3000}
# ensure build script exists
node -e "const p=require('./package.json'); if(!p.scripts||!p.scripts.build){console.error('ERROR: package.json missing build script'); process.exit(1); }" || { echo "ERROR: build script missing" >&2; exit 14; }
# run build capturing logs
npm run build --silent > /tmp/build.log 2>&1 || { echo "ERROR: build failed; see /tmp/build.log" >&2; sed -n '1,200p' /tmp/build.log >&2 || true; exit 15; }
# choose serve binary
if [ -x ./node_modules/.bin/serve ]; then
  SERVE_BIN="./node_modules/.bin/serve"
elif command -v serve >/dev/null 2>&1; then
  SERVE_BIN="$(command -v serve)"
else
  echo "ERROR: 'serve' binary not found locally or globally; ensure 'serve' is installed" >&2; exit 16
fi
LOG=/tmp/serve_out.log
# start server: prefer setsid but verify success
if command -v setsid >/dev/null 2>&1; then
  setsid "$SERVE_BIN" -s build -l 0.0.0.0:$PORT >"$LOG" 2>&1 &
else
  "$SERVE_BIN" -s build -l 0.0.0.0:$PORT >"$LOG" 2>&1 &
fi
SERVE_PID=$!
sleep 0.2
if ! kill -0 "$SERVE_PID" >/dev/null 2>&1; then echo "ERROR: serve process died immediately; tail $LOG" >&2; sed -n '1,200p' "$LOG" >&2 || true; exit 17; fi
# determine PGID safely
PGID=$(ps -o pgid= -p "$SERVE_PID" 2>/dev/null | tr -d ' ' || true)
cleanup() {
  if [ -n "${PGID:-}" ] && [ "$PGID" != "" ]; then
    pkill -TERM -g "$PGID" 2>/dev/null || true; sleep 1; pkill -KILL -g "$PGID" 2>/dev/null || true
  else
    if [ -n "${SERVE_PID:-}" ]; then kill -TERM "$SERVE_PID" 2>/dev/null || true; sleep 1; kill -KILL "$SERVE_PID" 2>/dev/null || true; fi
  fi
}
trap cleanup EXIT
# wait for server (max 45s)
RETRIES=45
SLEEP=1
OK=0
for i in $(seq 1 $RETRIES); do
  HTTP=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$PORT/" || true)
  if [ -n "$HTTP" ] && [ "$HTTP" != "" ] && [[ "$HTTP" =~ ^2[0-9][0-9]$ ]]; then OK=1; break; fi
  # try index.html as fallback
  HTTP2=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$PORT/index.html" || true)
  if [ -n "$HTTP2" ] && [[ "$HTTP2" =~ ^2[0-9][0-9]$ ]]; then OK=1; break; fi
  sleep $SLEEP
done
if [ "$OK" -ne 1 ]; then
  echo "ERROR: server did not respond with 2xx on $PORT; tailing serve log" >&2
  sed -n '1,300p' "$LOG" >&2 || true
  exit 18
fi
echo "VALIDATION_OK: http://127.0.0.1:$PORT/ responded with 2xx"
# cleanup will run via trap
exit 0
