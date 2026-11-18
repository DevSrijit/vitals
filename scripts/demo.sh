#!/usr/bin/env bash
# Try Vitals without a watch: builds a synthetic 35-day export, runs the pipeline on it, and opens the
# dashboard on that data. Everything goes to .demo/, never to data/, so it cannot mix with real data.
#
#   scripts/demo.sh          build the demo data and start the dashboard on http://localhost:3000
#   scripts/demo.sh --data   only build .demo/vitals.db
set -euo pipefail

cd "$(dirname "$0")/.."
DEMO="$PWD/.demo"
rm -rf "$DEMO"
mkdir -p "$DEMO"

cat > "$DEMO/config.yaml" <<EOF
profile:
  sex: male
  birth_year: 1994
  height_cm: 178
  weight_kg: 76
  sleep_need_base_h: 8.0
timezone: Asia/Kolkata
paths:
  inbox: $DEMO/inbox
  db: $DEMO/vitals.db
  reports: $DEMO/reports
EOF

uv run python scripts/make_fixture.py "$DEMO/fixture.zip"
uv run vitals --config "$DEMO/config.yaml" ingest "$DEMO/fixture.zip"
uv run vitals --config "$DEMO/config.yaml" compute
uv run vitals --config "$DEMO/config.yaml" today

if [[ "${1:-}" == "--data" ]]; then
  echo "Demo database: $DEMO/vitals.db"
  exit 0
fi

cd web
[[ -d node_modules ]] || bun install
VITALS_DB="$DEMO/vitals.db" bun run dev
