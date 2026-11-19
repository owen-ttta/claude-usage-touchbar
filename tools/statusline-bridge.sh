#!/bin/bash
# Statusline bridge for claude-usage-touchbar.
#
# Claude Code pipes a JSON blob to your status line command on every update.
# This publishes only four fields from it — effort level, model name, and the
# 5h / 7d reset times — to ~/.claude-usage-touchbar/model, which the widget
# reads for its model/effort column and the 7d reset countdown.
#
# Use from an existing status line script (after `input=$(cat)`):
#     printf '%s' "$input" | ~/bin/claude-touchbar-bridge.sh
# Install with: make install-script
#
# Output format (one line): "<effort>\t<model>\t<reset5 epoch>\t<reset7 epoch>"
set -u
umask 077

tb_dir="$HOME/.claude-usage-touchbar"
[ -d "$tb_dir" ] && [ ! -L "$tb_dir" ] && [ -O "$tb_dir" ] || exit 0

PY=/usr/bin/python3
[ -x "$PY" ] || PY=$(command -v python3) || exit 0

tb_line=$("$PY" -I -c '
import json, re, sys
try: d = json.load(sys.stdin)
except Exception: sys.exit(0)
c = lambda s: re.sub(r"[^A-Za-z0-9 ._-]", "", str(s or ""))[:24].strip()
m = c((d.get("model") or {}).get("display_name"))
e = c((d.get("effort") or {}).get("level")) or "-"
rl = d.get("rate_limits") or {}
def r(k):
    v = (rl.get(k) or {}).get("resets_at")
    return str(int(v)) if isinstance(v, (int, float)) and v > 0 else "0"
if m: print(e + "\t" + m + "\t" + r("five_hour") + "\t" + r("seven_day"))' 2>/dev/null)

[ -n "$tb_line" ] || exit 0
tb_tmp=$(mktemp "$tb_dir/.model.XXXXXX" 2>/dev/null) || exit 0
printf '%s\n' "$tb_line" > "$tb_tmp" && chmod 600 "$tb_tmp" && mv -f "$tb_tmp" "$tb_dir/model"
rm -f "$tb_tmp" 2>/dev/null
exit 0
