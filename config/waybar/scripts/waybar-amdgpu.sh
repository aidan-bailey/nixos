data=$(amdgpu_top --json -s 1000 -n 1 2>/dev/null)
if [ -z "$data" ]; then
  printf '{"text":"N/A","class":"unavailable"}\n'
  exit 0
fi
python3 - "$data" <<'EOF'
import sys, json
d = json.loads(sys.argv[1])
dev = d.get("devices", [{}])[0]
pct = dev.get("gpu_activity", {}).get("GFX", {}).get("value", None)
used = dev.get("vram_usage", {}).get("Total VRAM Usage", {}).get("value", 0)
total = dev.get("vram_usage", {}).get("Total VRAM", {}).get("value", 1)
if pct is None:
    print('{"text":"N/A","class":"unavailable"}')
else:
    tip = f"AMD GFX: {pct}%\nVRAM: {used}/{total} MB"
    print(json.dumps({"text": f"{pct}%", "tooltip": tip, "percentage": int(pct), "class": "gpu"}))
EOF
