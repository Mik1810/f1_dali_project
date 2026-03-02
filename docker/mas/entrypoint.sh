#!/bin/bash
# Runs startmas.sh on startup, then watches the shared tmux-socket volume for a
# restart trigger written by the UI container (dashboard.py → /api/restart).
#
# Trigger protocol:
#   UI writes   /tmp/tmux-shared/.restart   (any content, just presence matters)
#   This script detects it, removes it, and re-runs startmas.sh.
#
# Non-blocking design:
#   startmas.sh runs in the BACKGROUND so the watch loop is always responsive.
#   A restart trigger is detected within 1 s even during a startup sequence.

TRIGGER=/tmp/tmux-shared/.restart
WORKDIR=/dali/Examples/f1_race
MAS_PID=""

run_mas_bg() {
    rm -f "$TRIGGER"   # consume trigger before launching to avoid immediate re-trigger
    cd "$WORKDIR"
    # Background + stdin=/dev/null → [ -t 0 ] is false inside startmas.sh,
    # so the interactive "tmux attach / Press Enter" block is skipped.
    bash startmas.sh < /dev/null &
    MAS_PID=$!
    echo "[entrypoint] startmas.sh started (PID $MAS_PID)"
}

echo "[entrypoint] Starting MAS for the first time..."
run_mas_bg

echo "[entrypoint] Entering restart-watch loop (trigger: $TRIGGER)"
while true; do
    # Reap naturally-exited startmas.sh to keep MAS_PID accurate.
    if [ -n "$MAS_PID" ] && ! kill -0 "$MAS_PID" 2>/dev/null; then
        wait "$MAS_PID" 2>/dev/null || true
        echo "[entrypoint] startmas.sh exited (was PID $MAS_PID)"
        MAS_PID=""
    fi

    if [ -f "$TRIGGER" ]; then
        echo "[entrypoint] Restart trigger detected — relaunching startmas.sh..."
        # Kill any still-running startmas.sh so the flock is released immediately.
        # startmas.sh will then do its own full cleanup before starting the MAS.
        if [ -n "$MAS_PID" ] && kill -0 "$MAS_PID" 2>/dev/null; then
            kill -9 "$MAS_PID" 2>/dev/null || true
            wait "$MAS_PID" 2>/dev/null || true
        fi
        MAS_PID=""
        run_mas_bg
        echo "[entrypoint] startmas.sh relaunched (PID $MAS_PID)"
    fi

    sleep 1
done
