lat="${WAYBAR_WEATHER_LAT:--33.9}"
lon="${WAYBAR_WEATHER_LON:-18.4}"
data=$(curl -sf --max-time 10 \
  "https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,weather_code,relative_humidity_2m,apparent_temperature,wind_speed_10m" \
  2>/dev/null)
[ -z "$data" ] && printf '{"text":"󰖑 N/A","class":"unavailable"}\n' && exit 0
python3 - "$data" <<'EOF'
import sys, json
d = json.loads(sys.argv[1])
c = d["current"]
code = c.get("weather_code", 0)
if code == 0: icon = "󰖙"
elif code in (1,2): icon = "󰖕"
elif code == 3: icon = "󰖐"
elif code in (45,48): icon = "󰖑"
elif code in (51,53,55,56,57,61,63,65,66,67,80,81,82): icon = "󰖗"
elif code in (71,73,75,77,85,86): icon = "󰼶"
elif code in (95,96,99): icon = "󰖓"
else: icon = "󰖑"
temp = c["temperature_2m"]
feels = c["apparent_temperature"]
hum = c["relative_humidity_2m"]
wind = c["wind_speed_10m"]
wmo = {0:"Clear",1:"Mainly clear",2:"Partly cloudy",3:"Overcast",45:"Fog",48:"Rime fog",
       51:"Light drizzle",53:"Drizzle",55:"Dense drizzle",56:"Freezing drizzle",57:"Dense freezing drizzle",
       61:"Light rain",63:"Rain",65:"Heavy rain",66:"Freezing rain",67:"Heavy freezing rain",
       71:"Light snow",73:"Snow",75:"Heavy snow",77:"Snow grains",
       80:"Light showers",81:"Showers",82:"Heavy showers",85:"Snow showers",86:"Heavy snow showers",
       95:"Thunderstorm",96:"Thunderstorm w/ hail",99:"Heavy thunderstorm w/ hail"}
desc = wmo.get(code, "Unknown")
tip = f"{desc}\n{temp}°C (feels {feels}°C)\nHumidity: {hum}%\nWind: {wind} km/h"
print(json.dumps({"text": f"{icon} {temp}°C", "tooltip": tip, "class": "weather"}))
EOF
