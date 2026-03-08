count=$(swaync-client -swb 2>/dev/null \
  | python3 -c \
    "import sys,json; d=json.load(sys.stdin); print(d.get('count',0))" 2>/dev/null || echo 0)
dnd=$(swaync-client -D 2>/dev/null | tr -d '[:space:]' || echo false)
if [ "$dnd" = "true" ]; then
  printf '{"text":"󰂛","tooltip":"DND on","class":"dnd"}\n'
elif [ "$(( count + 0 ))" -gt 0 ] 2>/dev/null; then
  printf '{"text":"󰂞 %s","tooltip":"%s notifications","class":"notification"}\n' "$count" "$count"
else
  printf '{"text":"󰂚","tooltip":"No notifications","class":"none"}\n'
fi
