-- AwesomeWM Optimized System Monitor Widget v2
-- Place this in: ~/.config/awesome/widgets/sysmon.lua
-- Optimizations: cached calculations, lookup tables, reduced allocations

local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")

local sysmon = {}

-- Configuration
local UPDATE_INTERVAL = 2  -- seconds
local TEMP_PATH = "/sys/class/hwmon/hwmon5/temp1_input"

-- Color lookup tables (pre-calculated, no runtime ternary chains)
local COLOR_GREEN = "#51cf66"
local COLOR_YELLOW = "#ffd93d"
local COLOR_RED = "#ff6b6b"

local function get_threshold_color(value, warn, crit)
    if value > crit then return COLOR_RED end
    if value > warn then return COLOR_YELLOW end
    return COLOR_GREEN
end

-- Cached file handles and buffers
local stat_file = io.open("/proc/stat", "r")
local meminfo_file = io.open("/proc/meminfo", "r")
local temp_file = io.open(TEMP_PATH, "r")

-- Validate temperature sensor exists
if not temp_file then
    print("[sysmon] Warning: CPU temperature sensor not found at " .. TEMP_PATH)
end

-- Helper function to read file efficiently with seek rewind
local function read_file_cached(file)
    if not file then return nil end
    file:seek("set", 0)  -- Rewind to start (faster than close/reopen)
    local content = file:read("*all")
    return content
end

-- CPU usage calculation (optimized with direct parsing)
local prev_idle, prev_total = 0, 0
local function get_cpu_usage()
    local content = read_file_cached(stat_file)
    if not content then return 0 end
    
    -- Parse first line only (cpu aggregate)
    local vals = {}
    for num in content:match("cpu%s+([^\n]+)"):gmatch("%d+") do
        vals[#vals + 1] = tonumber(num)
    end
    
    -- vals = {user, nice, system, idle, iowait, irq, softirq, ...}
    local idle_time = vals[4] + vals[5]  -- idle + iowait
    local total_time = vals[1] + vals[2] + vals[3] + idle_time + vals[6] + vals[7]
    
    local diff_idle = idle_time - prev_idle
    local diff_total = total_time - prev_total
    
    prev_idle = idle_time
    prev_total = total_time
    
    if diff_total == 0 then return 0 end
    
    return math.floor((1 - diff_idle / diff_total) * 100 + 0.5)
end

-- RAM usage (optimized pattern matching)
local function get_ram_usage()
    local content = read_file_cached(meminfo_file)
    if not content then return 0 end
    
    local total = tonumber(content:match("MemTotal:%s*(%d+)"))
    local available = tonumber(content:match("MemAvailable:%s*(%d+)"))
    
    if not total or not available then return 0 end
    
    return math.floor((total - available) / total * 100 + 0.5)
end

-- CPU temperature (optimized with cached file handle)
local function get_cpu_temp()
    local content = read_file_cached(temp_file)
    if not content then return "N/A" end
    
    local temp = tonumber(content)
    if not temp then return "N/A" end
    
    return math.floor(temp / 1000 + 0.5)
end

-- Pre-allocated format strings (reduces string allocation overhead)
local fmt_cpu = '<span foreground="%s">  %d%%</span>'
local fmt_ram = '<span foreground="%s"> %d%%</span>'
local fmt_temp = '<span foreground="%s">󰔏%d°C</span>'

-- Create the widget
function sysmon.create()
    local widget = wibox.widget {
        {
            {
                id = "cpu_text",
                widget = wibox.widget.textbox,
            },
            {
                id = "ram_text",
                widget = wibox.widget.textbox,
            },
            {
                id = "temp_text",
                widget = wibox.widget.textbox,
            },
            layout = wibox.layout.fixed.horizontal,
            spacing = 12
        },
        margins = 6,
        widget = wibox.container.margin
    }
    
    local cpu_text = widget:get_children_by_id("cpu_text")[1]
    local ram_text = widget:get_children_by_id("ram_text")[1]
    local temp_text = widget:get_children_by_id("temp_text")[1]
    
    -- Update function
    local function update()
        local cpu = get_cpu_usage()
        local ram = get_ram_usage()
        local temp = get_cpu_temp()
        
        -- Use lookup table for colors (faster than nested ternary)
        local cpu_color = get_threshold_color(cpu, 50, 80)
        local ram_color = get_threshold_color(ram, 60, 80)
        
        -- Temperature color logic (different thresholds)
        local temp_color = COLOR_GREEN
        if type(temp) == "number" then
            temp_color = get_threshold_color(temp, 70, 85)
        end
        
        cpu_text:set_markup(string.format(fmt_cpu, cpu_color, cpu))
        ram_text:set_markup(string.format(fmt_ram, ram_color, ram))
        
        if type(temp) == "number" then
            temp_text:set_markup(string.format(fmt_temp, temp_color, temp))
        else
            temp_text:set_markup('<span foreground="#888">󰔏 N/A</span>')
        end
    end
    
    -- Initial update
    update()
    
    -- Set up timer
    gears.timer {
        timeout = UPDATE_INTERVAL,
        call_now = false,
        autostart = true,
        callback = update
    }
    
    return widget
end

return sysmon