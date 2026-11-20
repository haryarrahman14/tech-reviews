#!/bin/sh
# Build, start the app, check every route, then load each Go/TypeScript pair with oha.
#   sh bench.sh        needs: Go 1.24+, pnpm, oha. Everything in results/ is written by this script and lifecycle.sh.
#   GOMAXPROCS=1 OUT=results/one-core sh bench.sh     the same with Go held to one core, like Node's one thread
set -e
cd "$(dirname "$0")"
PORT=3210; U=http://127.0.0.1:$PORT; OUT=${OUT:-results}
mkdir -p $OUT
if lsof -ti tcp:$PORT -sTCP:LISTEN > /dev/null; then echo "port $PORT is in use"; exit 1; fi
(cd app && pnpm build > ../$OUT/build.txt 2>&1)
sed -i.bak "s#$PWD/##g" $OUT/build.txt && rm $OUT/build.txt.bak   # no machine paths in the results
(cd app && exec node_modules/.bin/next start -p $PORT > ../$OUT/server.log 2>&1) &
trap 'kill $(lsof -ti tcp:$PORT -sTCP:LISTEN) 2>/dev/null || true' EXIT   # the server renames itself, so find it by port
until curl -s -o /dev/null $U/; do sleep 0.2; done

{
  echo "## first request (cold), seconds"
  for r in hello-go hello-ts; do printf "$r "; curl -s -o /dev/null -w '%{time_total}\n' $U/api/$r; done
  echo "## behaviour"
  for r in hello-go hello-ts env-go "items-go/42?name=cat" "items-ts/42?name=cat" "prime-go?n=100000" "prime-ts?n=100000"; do
    printf "GET $r -> "; curl -s -w ' [%{http_code}]\n' "$U/api/$r"; done
  for r in items-go items-ts; do
    printf "POST $r -> "; curl -s -w ' [%{http_code}]\n' -X POST -d '{"name":"cat"}' $U/api/$r/7
    printf "POST $r bad JSON -> "; curl -s -w ' [%{http_code}]\n' -X POST -d '{' $U/api/$r/7
    printf "PUT $r -> "; curl -s -o /dev/null -w '[%{http_code}]\n' -X PUT $U/api/$r/7
    printf "OPTIONS $r -> "; curl -s -o /dev/null -D - -X OPTIONS $U/api/$r/7 | grep -iE '^(HTTP|allow)' | tr -d '\r' | tr '\n' ' '; echo
  done
  printf "stream-go, time to each chunk: "; curl -sN $U/api/stream-go | while read l; do printf "$l@$(date +%S.%N | cut -c1-6) "; done; echo
} > $OUT/behaviour.txt 2>&1

for pair in "hello-go" "hello-ts" "items-go/42?name=cat" "items-ts/42?name=cat" "prime-go?n=100000" "prime-ts?n=100000"; do
  name=$(echo $pair | cut -d/ -f1 | cut -d'?' -f1)
  oha -z 5s -c 50 --no-tui "$U/api/$pair" > /dev/null          # warm up
  oha -z 15s -c 50 --no-tui --output-format json "$U/api/$pair" > $OUT/oha-$name.json
done

{ echo "## processes after load (RSS in MB)"; ps -axo rss,command | grep -E "next-server \(v16.5|$PWD/app/.next/server" | grep -v grep | awk '{printf "%.0f MB  ", $1/1024; $1=""; print}' | sed "s#$PWD/##"
  echo "## compiled Go files"; find app/.next/server/app -type f -name 'route-*' ! -name '*.*' -exec ls -lh {} \; | awk '{print $5, $9}'; } > $OUT/processes.txt
OUT=$OUT python3 - <<'P' | tee $OUT/summary.txt
import json,glob,os
print(f"{'route':10} {'req/s':>9} {'p50 ms':>8} {'p99 ms':>8} {'ok %':>6}")
for f in sorted(glob.glob(os.environ.get('OUT','results')+'/oha-*.json')):
    d=json.load(open(f)); s=d['summary']; p=d['latencyPercentiles']
    print(f"{os.path.basename(f)[4:-5]:10} {s['requestsPerSec']:9.0f} {p['p50']*1000:8.2f} {p['p99']*1000:8.2f} {s['successRate']*100:6.1f}")
P

# What a Go syntax error looks like at build time: break one route, build, put it back.
cp app/app/api/hello-go/route.go $OUT/route.go.keep
echo 'func broken( {' >> app/app/api/hello-go/route.go
(cd app && pnpm build 2>&1 | grep -v "^    at " | sed "s#$PWD/##g" > ../$OUT/compile-error.txt) || true
mv $OUT/route.go.keep app/app/api/hello-go/route.go
rm -f $OUT/server.log
