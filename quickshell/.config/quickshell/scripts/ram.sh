#!/bin/sh

# Get memory info in kB
mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
mem_available=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
mem_used=$((mem_total - mem_available))

# Convert to MB
used_mb=$((mem_used / 1024))
total_mb=$((mem_total / 1024))

# Format used
if [ "$used_mb" -ge 1024 ]; then
    used_gb_int=$((used_mb / 1024))
    used_gb_dec=$(( (used_mb % 1024) * 10 / 1024 ))
    used_fmt="${used_gb_int}.${used_gb_dec}G"
else
    used_fmt="${used_mb}M"
fi

# Format total
if [ "$total_mb" -ge 1024 ]; then
    total_gb_int=$((total_mb / 1024))
    total_gb_dec=$(( (total_mb % 1024) * 10 / 1024 ))
    total_fmt="${total_gb_int}.${total_gb_dec}G"
else
    total_fmt="${total_mb}M"
fi

echo " ${used_fmt} / ${total_fmt}"
