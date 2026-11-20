#!/bin/sh
# When do Go workers start, what do they inherit, and do they stop with the server?
#   sh lifecycle.sh      builds, then starts the server three times. Writes results/lifecycle.txt
cd "$(dirname "$0")/app"
PORT=3210; U=http://127.0.0.1:$PORT
workers() { pgrep -f "$PWD/.next/server/app/api" | wc -l | tr -d ' '; }
server() { lsof -ti tcp:$PORT -sTCP:LISTEN; }
t() { printf "$1 "; curl -s -o /dev/null -w '%{time_total}s\n' "$U/api/$2"; }
pnpm build > /dev/null 2>&1 || { echo "build failed"; exit 1; }   # its own build, so the first start below is the first after a build
{
for SIG in TERM INT KILL; do
  echo "=== server stopped with SIG$SIG"
  GOMAXPROCS=1 node_modules/.bin/next start -p $PORT > /dev/null 2>&1 &
  until curl -s -o /dev/null $U/; do sleep 0.2; done
  echo "workers before any Go request: $(workers)"
  t "hello-go 1st" hello-go; t "hello-go 2nd" hello-go; t "hello-ts 1st" hello-ts; t "hello-ts 2nd" hello-ts
  echo "workers after one Go route was hit: $(workers)"
  echo "env-go: $(curl -s $U/api/env-go)"
  curl -s -o /dev/null $U/api/env-go; echo "env-go again: $(curl -s $U/api/env-go)"
  kill -$SIG $(server); sleep 3
  echo "3s after SIG$SIG: server listening=$(server | wc -l | tr -d ' ') workers alive=$(workers)"
  pkill -f "$PWD/.next/server/app/api"; sleep 1
done
} 2>&1 | grep -v "Killed: 9" > ../results/lifecycle.txt
cat ../results/lifecycle.txt
