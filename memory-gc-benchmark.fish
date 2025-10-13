#!/usr/bin/env fish
# memory-gc-cpu-benchmark-120s.fish

set LOGFILE ~/awesome_gc_cpu_120s.csv
echo "timestamp,seconds_elapsed,gc_kb,gc_post_collect_kb,delta_kb,delta_post_collect_kb,cpu_percent" > $LOGFILE

set start (date +%s)
set baseline (awesome-client 'return collectgarbage("count")' 2>/dev/null | grep -oP '\d+\.\d+' | head -n1 | string trim)
if test -z "$baseline"
    echo "Error: failed to get baseline GC"
    exit 1
end

echo "Baseline GC: "(math --scale=4 "$baseline / 1024")" MB"

set max_cpu 0
set sum_cpu 0
set count 0
set interval 10
set duration 120

for i in (seq $interval $interval $duration)
    sleep $interval

    set now (date +%s)
    set elapsed (math $now - $start)

    # GC memory raw
    set mem_raw (awesome-client 'return collectgarbage("count")' 2>/dev/null | grep -oP '\d+\.\d+' | head -n1 | string trim)
    if test -z "$mem_raw"
        set mem_raw 0
    end

    # Force GC
    set mem_gc (awesome-client 'collectgarbage("collect"); return collectgarbage("count")' 2>/dev/null | grep -oP '\d+\.\d+' | head -n1 | string trim)
    if test -z "$mem_gc"
        set mem_gc 0
    end

    set delta (math "$mem_raw - $baseline")
    set delta_gc (math "$mem_gc - $baseline")

    # CPU usage of Awesome
    set cpu (ps -p (pgrep awesome) -o %cpu= | string trim)
    set cpu_num (math "$cpu" 2>/dev/null || 0)

    # Track stats
    set sum_cpu (math "$sum_cpu + $cpu_num")
    set count (math "$count + 1")
    if test "$cpu_num" -gt "$max_cpu"
        set max_cpu $cpu_num
    end

    # Append CSV
    echo (date "+%H:%M:%S"),$elapsed,$mem_raw,$mem_gc,$delta,$delta_gc,$cpu_num >> $LOGFILE

    # Print live summary
    printf "[%3ds] GC: %.2f KB -> %.2f KB (Δ: %.1f / %.1f KB), CPU: %.1f%%\n" \
        $elapsed $mem_raw $mem_gc $delta $delta_gc $cpu_num
end

# Final stats
set final_raw (awk -F, 'END{print $3}' $LOGFILE)
set final_gc  (awk -F, 'END{print $4}' $LOGFILE)
set growth_raw (math "$final_raw - $baseline")
set growth_gc  (math "$final_gc - $baseline")
set avg_cpu (math "$sum_cpu / $count")

echo ""
echo "════════════════════════════════════"
echo "Final Memory + CPU Summary (120s)"
echo "Start GC (KB): $baseline"
echo "End Raw  (KB): $final_raw (Δ: $growth_raw KB)"
echo "End GC   (KB): $final_gc (Δ: $growth_gc KB)"
echo "Max CPU (%): $max_cpu"
echo "Avg CPU (%): $avg_cpu"

if test (math "$growth_gc < 50")
    echo "Status: ✓ No leak (GC noise only)"
else if test (math "$growth_gc < 200")
    echo "Status: ⚠ Minor leak"
else
    echo "Status: ✗ Leak persists!"
end
