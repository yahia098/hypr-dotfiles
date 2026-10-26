#!/usr/bin/env bash
# Prints CPU temperature in °C (integer).
for z in /sys/class/thermal/thermal_zone*; do
  case "$(cat "$z/type" 2>/dev/null)" in
    x86_pkg_temp|k10temp|cpu*|coretemp)
      echo $(( $(cat "$z/temp") / 1000 ))
      exit 0
      ;;
  esac
done

# Fallback: first thermal zone, then first hwmon sensor
if [ -r /sys/class/thermal/thermal_zone0/temp ]; then
  echo $(( $(cat /sys/class/thermal/thermal_zone0/temp) / 1000 ))
else
  t=$(cat /sys/class/hwmon/hwmon*/temp1_input 2>/dev/null | head -n1)
  echo $(( ${t:-0} / 1000 ))
fi
