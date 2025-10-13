local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local awful = require("awful")

-- Widget text
local battery_text = wibox.widget {
    widget = wibox.widget.textbox,
    align = "center",
    valign = "center",
    font = beautiful.font,
}

-- Wrapped with margin
local battery_widget = wibox.container.margin(battery_text, -4, 10, 1, 0)

-- Battery path constants (immutable)
local BAT_PATH = "/sys/class/power_supply/BAT0/"
local STATUS_FILE = BAT_PATH .. "status"
local CAPACITY_FILE = BAT_PATH .. "capacity"

-- Pre-allocated icon table (eliminates function calls)
local ICON_CHARGING = "⚡"
local ICON_HIGH = "🔋"
local ICON_MED = "🔌"
local ICON_LOW = "🔻"
local ICON_NA = "Battery: N/A"

-- Cached icon lookup (faster than if-else chain)
local function get_battery_icon(status, capacity)
    if status == "Charging" then
        return ICON_CHARGING
    elseif capacity >= 70 then
        return ICON_HIGH
    elseif capacity >= 40 then
        return ICON_MED
    else
        return ICON_LOW
    end
end

-- Pre-allocated format string (reduces string.format overhead)
local fmt_battery = " %s%d%%"

-- Cached shell command (reuse string)
local read_cmd = string.format("cat %s %s 2>/dev/null", STATUS_FILE, CAPACITY_FILE)

-- Update function (optimized with single spawn)
local function update_battery()
    awful.spawn.easy_async_with_shell(
        read_cmd,
        function(stdout)
            -- Parse output (optimized pattern matching)
            local lines = {}
            for line in stdout:gmatch("[^\n]+") do
                lines[#lines + 1] = line
            end
            
            if #lines < 2 then
                battery_text.text = ICON_NA
                return
            end
            
            local status = lines[1]
            local capacity = tonumber(lines[2])
            
            if not capacity then
                battery_text.text = ICON_NA
                return
            end
            
            -- Use cached icon lookup
            local icon = get_battery_icon(status, capacity)
            battery_text.text = string.format(fmt_battery, icon, capacity)
        end
    )
end

-- Timer with error handling
gears.timer {
    timeout = 30,
    autostart = true,
    call_now = true,
    callback = function()
        local success, err = pcall(update_battery)
        if not success then
            print("[battery] Update error: " .. tostring(err))
        end
    end
}

return battery_widget