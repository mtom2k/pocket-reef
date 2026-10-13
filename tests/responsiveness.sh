#!/usr/bin/env bash
# Responsiveness check (macOS): launches the tank HIDDEN and times how fast it answers
# Apple Events, which need the app's main thread just like menu-bar clicks do.
#
#   tests/responsiveness.sh            # uses `godot` from PATH; set GODOT=... to override
#
# Fails if the worst reply is slower than 600 ms. (osascript itself adds ~150-200 ms.)
# Regression guard for v0.2.2, where the hidden tank ticked once a second and the
# menu bar froze while its menu was open.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
DATA="$HOME/Library/Application Support/Fishtank"
SAVE="responsiveness_test.json"
python3 - "$DATA/$SAVE" <<'PY'
import json, sys, time
json.dump({"format": 2, "saved_at": time.time(), "next_id": 2,
           "fish": [{"id": 1, "species": "goldfish", "variant": "default", "name": "G", "hunger": 0.3}],
           "decor": [], "settings": {"tank_visible": False, "window_position": []}}, open(sys.argv[1], "w"))
PY
"$GODOT" --path . -- --save-file="user://$SAVE" >/dev/null 2>&1 &
PID=$!
trap 'kill $PID 2>/dev/null; rm -f "$DATA/$SAVE"' EXIT
sleep 4
python3 - <<'PY'
import subprocess, sys, time
ms = []
for _ in range(10):
    t = time.time()
    subprocess.run(["osascript", "-e", 'tell application id "org.godotengine.godot" to count windows'], capture_output=True)
    ms.append((time.time() - t) * 1000)
    time.sleep(0.4)
worst = max(ms)
print("hidden tank reply times (ms):", " ".join(f"{m:.0f}" for m in ms))
print(("PASS" if worst < 600 else "FAIL") + f"  worst reply {worst:.0f} ms (limit 600)")
sys.exit(0 if worst < 600 else 1)
PY
