pf=/sys/firmware/acpi/platform_profile
[ ! -f "$pf" ] && printf '{"text":"N/A","class":"unavailable"}\n' && exit 0
profile=$(cat "$pf" | tr -d '[:space:]')
case "$profile" in
  performance)             icon="󱐋"; class=performance ;;
  balanced*|balanced)      icon="󰾭"; class=balanced ;;
  low-power|power-saver|quiet) icon="󰔄"; class=power-saver ;;
  *)                       icon="󰾭"; class=balanced ;;
esac
printf '{"text":"%s %s","tooltip":"Profile: %s\nClick to cycle","class":"%s"}\n' \
  "$icon" "$profile" "$profile" "$class"
