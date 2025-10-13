#!/usr/bin/env fish
# AwesomeWM Memory + CPU Benchmark (Fish 3.x, CachyOS Optimized)
# Measures GC growth and CPU usage over 2 minutes with 10s intervals
# Usage: ./memory-gc-benchmark.fish

set LOGFILE ~/awesome_gc_cpu_benchmark.csv
set INTERVAL 10
set DURATION 120

# ============================================================================
# INITIALIZATION
# ============================================================================

# Get AwesomeWM PID (single process only)
set AWESOME_PID (pgrep -x awesome | head -n1)
if test -z "$AWESOME_PID"
    echo "Error: AwesomeWM not running"
    exit 1
end

# Establish baseline AFTER forcing GC (prevents false leak detection)
awesome-client 'collectgarbage("collect")' >/dev/null 2>&1
sleep 0.5 # Allow GC to complete

set BASELINE_RAW (awesome-client 'return collectgarbage("count")' 2>/dev/null | \
    string match -r '\d+\.\d+' | head -n1)

if test -z "$BASELINE_RAW"
    echo "Error: Failed to communicate with AwesomeWM via awesome-client"
    exit 1
end

set BASELINE (math --scale=1 "$BASELINE_RAW")
echo "Baseline GC: "(math --scale=2 "$BASELINE / 1024")" MB"

# CSV header
echo "timestamp,elapsed_sec,gc_kb,gc_post_collect_kb,delta_kb,delta_post_collect_kb,cpu_percent" > $LOGFILE

# ============================================================================
# MONITORING LOOP
# ============================================================================

set START_TIME (date +%s)
set STEPS (math "$DURATION / $INTERVAL")
set CPU_TOTAL 0
set CPU_MAX 0

for i in (seq 1 $STEPS)
    set NOW (date +%s)
    set ELAPSED (math "$NOW - $START_TIME")
    
    # Verify AwesomeWM still running
    if not kill -0 $AWESOME_PID 2>/dev/null
        echo "Error: AwesomeWM process died at $ELAPSED seconds"
        break
    end
    
    # Get raw GC memory (no forced collection yet)
    set MEM_RAW_STR (awesome-client 'return collectgarbage("count")' 2>/dev/null | \
        string match -r '\d+\.\d+' | head -n1)
    set MEM_RAW (test -n "$MEM_RAW_STR"; and math --scale=1 "$MEM_RAW_STR"; or echo "0")
    
    # Force GC and measure again (shows minimum footprint)
    set MEM_GC_STR (awesome-client 'collectgarbage("collect"); return collectgarbage("count")' 2>/dev/null | \
        string match -r '\d+\.\d+' | head -n1)
    set MEM_GC (test -n "$MEM_GC_STR"; and math --scale=1 "$MEM_GC_STR"; or echo "$MEM_RAW")
    
    # Calculate deltas
    set DELTA_RAW (math --scale=1 "$MEM_RAW - $BASELINE")
    set DELTA_GC (math --scale=1 "$MEM_GC - $BASELINE")
    
    # Get CPU usage (single process, average over sampling period)
    set CPU_PERCENT (ps -p $AWESOME_PID -o %cpu= | string trim)
    if test -z "$CPU_PERCENT"
        set CPU_PERCENT 0
    end
    
    # Update CPU stats (float-safe max comparison using awk)
    set CPU_TOTAL (math --scale=1 "$CPU_TOTAL + $CPU_PERCENT")
    set CPU_MAX (echo -e "$CPU_PERCENT\n$CPU_MAX" | awk 'BEGIN{max=0} {if($1>max) max=$1} END{printf "%.1f", max}')
    
    # Log to console and CSV
    set TIMESTAMP (date "+%H:%M:%S")
    echo "[$ELAPSED s] GC: $MEM_RAW KB → $MEM_GC KB (Δ: $DELTA_RAW / $DELTA_GC KB), CPU: $CPU_PERCENT%"
    echo "$TIMESTAMP,$ELAPSED,$MEM_RAW,$MEM_GC,$DELTA_RAW,$DELTA_GC,$CPU_PERCENT" >> $LOGFILE
    
    sleep $INTERVAL
end

# ============================================================================
# SUMMARY ANALYSIS
# ============================================================================

set FINAL_RAW (tail -n1 $LOGFILE | cut -d, -f3)
set FINAL_GC (tail -n1 $LOGFILE | cut -d, -f4)
set GROWTH_RAW (math --scale=1 "$FINAL_RAW - $BASELINE")
set GROWTH_GC (math --scale=1 "$FINAL_GC - $BASELINE")
set AVG_CPU (math --scale=1 "$CPU_TOTAL / $STEPS")

echo ""
echo "════════════════════════════════════════════════"
echo "Final Memory + CPU Summary ($DURATION s)"
echo "════════════════════════════════════════════════"
echo "Baseline GC (KB):     $BASELINE"
echo "Final Raw (KB):       $FINAL_RAW (Δ: $GROWTH_RAW KB)"
echo "Final Post-GC (KB):   $FINAL_GC (Δ: $GROWTH_GC KB)"
printf "Baseline GC (MB):     %.2f\n" (math "$BASELINE / 1024")
printf "Final Raw (MB):       %.2f (Δ: %.2f MB)\n" (math "$FINAL_RAW / 1024") (math "$GROWTH_RAW / 1024")
printf "Final Post-GC (MB):   %.2f (Δ: %.2f MB)\n" (math "$FINAL_GC / 1024") (math "$GROWTH_GC / 1024")
echo "Max CPU (%):          $CPU_MAX"
echo "Avg CPU (%):          $AVG_CPU"
echo "────────────────────────────────────────────────"

# Leak detection using awk for float comparison
set LEAK_STATUS (echo "$GROWTH_GC" | awk '{
    if ($1 < 50) print "✓ No leak (GC noise only)"
    else if ($1 < 200) print "⚠ Minor leak (" $1 " KB)"
    else print "✗ Memory leak detected! (" $1 " KB growth)"
}')

echo "Status: $LEAK_STATUS"
echo "════════════════════════════════════════════════"
echo "Log saved to: $LOGFILE"