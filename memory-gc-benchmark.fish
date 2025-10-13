#!/usr/bin/env fish
# ==============================================
# AwesomeWM GC & Memory Leak Benchmark (Fish)
# ==============================================

set LOGFILE ~/awesome_gc_leak.csv
echo "seq,timestamp,seconds_elapsed,gc_kb,gc_post_collect_kb,delta_kb,delta_post_collect_kb" > $LOGFILE

set START (date +%s)

# Baseline GC
set BASELINE (awesome-client 'return collectgarbage("count")' 2>/dev/null | grep -oP '\d+\.\d+' | head -n1 | string trim)
if test -z "$BASELINE"
    echo "Error: failed to get baseline GC"
    exit 1
end
echo "Baseline: "(math --scale=4 "$BASELINE / 1024")" MB"

# Print interval (seconds)
set INTERVAL 10

# Monitoring loop (120 seconds total)
for i in (seq 1 120)
    set NOW (date +%s)
    set ELAPSED (math "$NOW - $START")

    # Raw GC memory
    set MEM_RAW (awesome-client 'return collectgarbage("count")' 2>/dev/null | grep -oP '\d+\.\d+' | head -n1 | string trim)
    if test -z "$MEM_RAW"
        set MEM_RAW 0
    end

    # Force GC
    set MEM_GC (awesome-client 'collectgarbage("collect"); return collectgarbage("count")' 2>/dev/null | grep -oP '\d+\.\d+' | head -n1 | string trim)
    if test -z "$MEM_GC"
        set MEM_GC 0
    end

    set DELTA (math "$MEM_RAW - $BASELINE")
    set DELTA_GC (math "$MEM_GC - $BASELINE")

    # Print only every INTERVAL seconds
    if test (math "$i % $INTERVAL") -eq 0
        echo "[$i] $ELAPSED s - Raw: $MEM_RAW KB, GC: $MEM_GC KB, Δ: $DELTA KB, Δ GC: $DELTA_GC KB"
    end

    # Append to CSV (always)
    echo "$i,(date "+%H:%M:%S"),$ELAPSED,$MEM_RAW,$MEM_GC,$DELTA,$DELTA_GC" >> $LOGFILE

    sleep 1
end

# Summarize results
set FINAL_RAW (awk -F, 'END{print $4}' $LOGFILE)
set FINAL_GC (awk -F, 'END{print $5}' $LOGFILE)
set GROWTH_RAW (math "$FINAL_RAW - $BASELINE")
set GROWTH_GC (math "$FINAL_GC - $BASELINE")
set GROWTH_GC_INT (math "round($GROWTH_GC)")

echo ""
echo "════════════════════════════════════"
echo "Final Memory Summary"
echo "Start (KB): $BASELINE"
echo "End Raw  (KB): $FINAL_RAW (Δ: $GROWTH_RAW KB)"
echo "End GC   (KB): $FINAL_GC (Δ: $GROWTH_GC KB)"

if test $GROWTH_GC_INT -lt 50
    echo "Status: ✓ No leak (GC noise only)"
else if test $GROWTH_GC_INT -lt 200
    echo "Status: ⚠ Minor leak"
else
    echo "Status: ✗ Leak persists!"
end
