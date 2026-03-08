read -r gpu_pct mem_used mem_total temp < <(
  nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu \
             --format=csv,noheader,nounits 2>/dev/null | tr ',' ' '
)
[ -z "$gpu_pct" ] && printf '{"text":"N/A","class":"unavailable"}\n' && exit 0
gpu_pct=$(echo "$gpu_pct" | tr -d ' ')
mem_used=$(echo "$mem_used" | tr -d ' ')
mem_total=$(echo "$mem_total" | tr -d ' ')
temp=$(echo "$temp" | tr -d ' ')
tooltip="NVIDIA: ${gpu_pct}%\nVRAM: ${mem_used}/${mem_total} MiB\nTemp: ${temp}°C"
printf '{"text":"%s%%","tooltip":"%s","percentage":%s,"class":"gpu"}\n' \
  "$gpu_pct" "$tooltip" "$gpu_pct"
