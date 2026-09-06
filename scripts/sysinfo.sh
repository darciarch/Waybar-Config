#!/bin/bash
# custom/sysinfo — CPU + RAM in one capsule, single icon (no numbers). When a threshold
# is crossed the CSS class changes (normal → warning → critical) and the color turns
# orange/red. Exact numbers only in the hover tooltip. Dependency: jq. Called with `interval: 2`.

cpu_snap() { awk '/^cpu /{t=0; for(i=2;i<=NF;i++) t+=$i; print t, $5+$6}' /proc/stat; }

read -r t1 i1 < <(cpu_snap)
sleep 1
read -r t2 i2 < <(cpu_snap)
cpu=$(awk -v t1="$t1" -v i1="$i1" -v t2="$t2" -v i2="$i2" \
      'BEGIN{dt=t2-t1; di=i2-i1; printf "%d", (dt>0)?(100*(dt-di)/dt):0}')

read -r total avail < <(free -b | awk '/^Mem:/{print $2, $7}')
used=$(( total - avail ))
ram_pct=$(( 100 * used / total ))
ram_gi=$(awk -v u="$used" 'BEGIN{printf "%.1f", u/1073741824}')

class="normal"
if   (( cpu > 90 || ram_pct > 90 )); then class="critical"
elif (( cpu > 70 || ram_pct > 80 )); then class="warning"
fi

tooltip="CPU  ·  ${cpu}%"$'\n'"RAM  ·  ${ram_gi} Gi  (${ram_pct}%)"

icon=$'\uf4bc'   # nf-oct-cpu
jq -cn --arg text "$icon" --arg tooltip "$tooltip" --arg class "$class" \
    '{text:$text, tooltip:$tooltip, class:$class}'
