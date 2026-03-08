if command -v asusctl >/dev/null 2>&1; then
  current=$(asusctl profile -p 2>/dev/null | awk '{print $NF}')
  case "$current" in
    Quiet)       asusctl profile -P Balanced ;;
    Balanced)    asusctl profile -P Performance ;;
    Performance) asusctl profile -P Quiet ;;
    *)           asusctl profile -P Balanced ;;
  esac
fi
pkill -RTMIN+10 waybar
